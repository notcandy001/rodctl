package server

import (
	"encoding/json"
	"fmt"
	"net"
	"os"
	"os/exec"
	"sync"
	"time"

	"rodctl/pkg/compositor"
	"rodctl/pkg/state"
)

// ── JSON-RPC types ────────────────────────────────────────────────────────────

type Request struct {
	ID     interface{}     `json:"id"`
	Method string          `json:"method"`
	Params json.RawMessage `json:"params"`
}

type Response struct {
	ID     interface{} `json:"id"`
	Result interface{} `json:"result,omitempty"`
	Error  string      `json:"error,omitempty"`
}

type Notification struct {
	JSONRPC string          `json:"jsonrpc"`
	Method  string          `json:"method"`
	Params  interface{}     `json:"params,omitempty"`
	State   *state.Snapshot `json:"state,omitempty"`
}

// ── Server ────────────────────────────────────────────────────────────────────

type Server struct {
	comp       compositor.Compositor
	socketPath string
	cache      *state.Cache
	subs       map[net.Conn]struct{}
	subsMu     sync.RWMutex
}

func New(comp compositor.Compositor, socketPath string) *Server {
	return &Server{
		comp:       comp,
		socketPath: socketPath,
		cache:      state.New(),
		subs:       make(map[net.Conn]struct{}),
	}
}

func SocketPath() string {
	return fmt.Sprintf("/tmp/rodctl-%d.sock", os.Getuid())
}

func (s *Server) Start() error {
	s.refreshCache()
	go s.watchEvents()

	_ = os.Remove(s.socketPath)
	l, err := net.Listen("unix", s.socketPath)
	if err != nil {
		return err
	}
	defer l.Close()

	for {
		conn, err := l.Accept()
		if err != nil {
			continue
		}
		go s.handleConn(conn)
	}
}

func (s *Server) refreshCache() {
	if ws, err := s.comp.ListWindows(); err == nil {
		s.cache.SetWindows(ws)
	}
	if wss, err := s.comp.ListWorkspaces(); err == nil {
		s.cache.SetWorkspaces(wss)
	}
	if ms, err := s.comp.ListMonitors(); err == nil {
		s.cache.SetMonitors(ms)
	}
}

// ── Event watcher ─────────────────────────────────────────────────────────────

func (s *Server) watchEvents() {
	for {
		ch, err := s.comp.Subscribe()
		if err != nil {
			time.Sleep(2 * time.Second)
			continue
		}
		for ev := range ch {
			s.handleEvent(ev)
		}
		time.Sleep(1 * time.Second)
	}
}

func (s *Server) handleEvent(ev compositor.Event) {
	switch ev.Type {
	case compositor.EventWindowCreated:
		s.refreshCache()
		s.broadcast("Event.WindowCreated", ev.Payload)
	case compositor.EventWindowClosed:
		if addr, ok := ev.Payload["address"].(string); ok {
			s.cache.RemoveWindow(addr)
		}
		s.broadcast("Event.WindowClosed", ev.Payload)
	case compositor.EventWindowFocused:
		if addr, ok := ev.Payload["address"].(string); ok {
			s.cache.MarkFocused(addr)
		}
		s.broadcast("Event.WindowFocused", ev.Payload)
	case compositor.EventWindowTitle:
		if addr, ok := ev.Payload["address"].(string); ok {
			if title, ok := ev.Payload["title"].(string); ok {
				s.cache.UpdateTitle(addr, title)
			}
		}
		s.broadcast("Event.WindowTitle", ev.Payload)
	case compositor.EventWindowMoved:
		s.refreshCache()
		s.broadcast("Event.WindowMoved", ev.Payload)
	case compositor.EventWorkspaceChanged:
		s.refreshCache()
		s.broadcast("Event.WorkspaceChanged", ev.Payload)
	case compositor.EventMonitorChanged:
		s.refreshCache()
		s.broadcast("Event.MonitorChanged", ev.Payload)
	case compositor.EventFullscreen:
		s.broadcast("Event.FullscreenChanged", ev.Payload)
	case compositor.EventFloating:
		s.broadcast("Event.FloatingChanged", ev.Payload)
	}
}

func (s *Server) broadcast(method string, params interface{}) {
	s.subsMu.RLock()
	defer s.subsMu.RUnlock()
	if len(s.subs) == 0 {
		return
	}
	snap := s.cache.Snapshot()
	notif := Notification{
		JSONRPC: "2.0",
		Method:  method,
		Params:  params,
		State:   &snap,
	}
	data, err := json.Marshal(notif)
	if err != nil {
		return
	}
	data = append(data, '\n')
	for conn := range s.subs {
		go conn.Write(data)
	}
}

// ── Connection handler ────────────────────────────────────────────────────────

func (s *Server) handleConn(conn net.Conn) {
	defer func() {
		s.subsMu.Lock()
		delete(s.subs, conn)
		s.subsMu.Unlock()
		conn.Close()
	}()

	dec := json.NewDecoder(conn)
	enc := json.NewEncoder(conn)

	for {
		var req Request
		if err := dec.Decode(&req); err != nil {
			return
		}
		resp := Response{ID: req.ID}
		result, err := s.dispatch(conn, req)
		if err != nil {
			resp.Error = err.Error()
		} else {
			resp.Result = result
		}
		enc.Encode(resp)
	}
}

func (s *Server) resolveWindow(id string) (string, error) {
	if id != "" {
		return id, nil
	}
	return s.comp.ActiveWindowID()
}

// ── Dispatcher ────────────────────────────────────────────────────────────────

func (s *Server) dispatch(conn net.Conn, req Request) (interface{}, error) {
	switch req.Method {

	case "System.Subscribe":
		s.subsMu.Lock()
		s.subs[conn] = struct{}{}
		s.subsMu.Unlock()
		snap := s.cache.Snapshot()
		notif := Notification{JSONRPC: "2.0", Method: "State.Dump", State: &snap}
		data, _ := json.Marshal(notif)
		conn.Write(append(data, '\n'))
		return "subscribed", nil

	// Window
	case "Window.List":
		return s.cache.GetWindows(), nil
	case "Window.Active":
		id, err := s.comp.ActiveWindowID()
		return map[string]string{"id": id}, err
	case "Window.Focus":
		var p struct{ ID string `json:"id"` }
		json.Unmarshal(req.Params, &p)
		id, err := s.resolveWindow(p.ID)
		if err != nil { return nil, err }
		return "ok", s.comp.FocusWindow(id)
	case "Window.FocusDir":
		var p struct{ Dir string `json:"dir"` }
		json.Unmarshal(req.Params, &p)
		return "ok", s.comp.FocusDir(p.Dir)
	case "Window.Close":
		var p struct{ ID string `json:"id"` }
		json.Unmarshal(req.Params, &p)
		id, _ := s.resolveWindow(p.ID)
		return "ok", s.comp.CloseWindow(id)
	case "Window.Move":
		var p struct { ID, Dir string `json:"id" json2:"dir"` }
		json.Unmarshal(req.Params, &p)
		id, _ := s.resolveWindow(p.ID)
		return "ok", s.comp.MoveWindow(id, p.Dir)
	case "Window.Resize":
		var p struct { ID string `json:"id"`; W, H int `json:"w" json2:"h"` }
		json.Unmarshal(req.Params, &p)
		id, _ := s.resolveWindow(p.ID)
		return "ok", s.comp.ResizeWindow(id, p.W, p.H)
	case "Window.ToggleFloat":
		var p struct{ ID string `json:"id"` }
		json.Unmarshal(req.Params, &p)
		id, _ := s.resolveWindow(p.ID)
		return "ok", s.comp.ToggleFloating(id)
	case "Window.Fullscreen":
		var p struct { ID string `json:"id"`; On bool `json:"on"` }
		json.Unmarshal(req.Params, &p)
		id, _ := s.resolveWindow(p.ID)
		return "ok", s.comp.SetFullscreen(id, p.On)

	// Workspace
	case "Workspace.List":
		return s.cache.GetWorkspaces(), nil
	case "Workspace.Active":
		return s.comp.ActiveWorkspace()
	case "Workspace.Switch":
		var p struct{ ID string `json:"id"` }
		json.Unmarshal(req.Params, &p)
		return "ok", s.comp.SwitchWorkspace(p.ID)
	case "Workspace.MoveTo":
		var p struct { WindowID, WsID string `json:"window_id" json2:"ws_id"` }
		json.Unmarshal(req.Params, &p)
		id, _ := s.resolveWindow(p.WindowID)
		return "ok", s.comp.MoveToWorkspace(id, p.WsID)
	case "Workspace.ToggleSpecial":
		var p struct{ Name string `json:"name"` }
		json.Unmarshal(req.Params, &p)
		return "ok", s.comp.ToggleSpecialWorkspace(p.Name)

	// Monitor
	case "Monitor.List":
		return s.cache.GetMonitors(), nil

	// System
	case "System.Execute":
		var p struct{ Cmd string `json:"cmd"` }
		json.Unmarshal(req.Params, &p)
		return "ok", s.comp.Execute(p.Cmd)

	default:
		return nil, fmt.Errorf("method not found: %s", req.Method)
	}
}

// ── Client helpers (used by the CLI) ─────────────────────────────────────────

func Dial() (net.Conn, error) {
	return net.DialTimeout("unix", SocketPath(), 2*time.Second)
}

func IsDaemonRunning() bool {
	conn, err := net.DialTimeout("unix", SocketPath(), time.Second)
	if err != nil {
		return false
	}
	conn.Close()
	return true
}

func RPC(method string, params interface{}, out interface{}) error {
	conn, err := Dial()
	if err != nil {
		return fmt.Errorf("rodctl daemon not running — start it first: rodctl daemon")
	}
	defer conn.Close()

	if err := json.NewEncoder(conn).Encode(map[string]interface{}{
		"id": 1, "method": method, "params": params,
	}); err != nil {
		return err
	}

	var resp struct {
		Result json.RawMessage `json:"result"`
		Error  string          `json:"error"`
	}
	if err := json.NewDecoder(conn).Decode(&resp); err != nil {
		return err
	}
	if resp.Error != "" {
		return fmt.Errorf("%s", resp.Error)
	}
	if out != nil {
		return json.Unmarshal(resp.Result, out)
	}
	return nil
}

func RPCprint(method string, params interface{}) error {
	var result json.RawMessage
	if err := RPC(method, params, &result); err != nil {
		return err
	}
	var s string
	if json.Unmarshal(result, &s) == nil && (s == "ok" || s == "subscribed") {
		return nil
	}
	var v interface{}
	json.Unmarshal(result, &v)
	out, _ := json.MarshalIndent(v, "", "  ")
	fmt.Println(string(out))
	return nil
}

// QsIPC calls qs ipc for CrescentShell panel commands.
func QsIPC(target, fn string) error {
	cmd := exec.Command("qs", "ipc", "call", target, fn)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}
