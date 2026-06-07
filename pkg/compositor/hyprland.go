package compositor

import (
	"bufio"
	"encoding/json"
	"fmt"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
)

// Hyprland implements Compositor for the Hyprland compositor.
type Hyprland struct{}

// NewHyprland returns a new Hyprland compositor handle or an error if
// HYPRLAND_INSTANCE_SIGNATURE is not set.
func NewHyprland() (*Hyprland, error) {
	if os.Getenv("HYPRLAND_INSTANCE_SIGNATURE") == "" {
		return nil, fmt.Errorf("HYPRLAND_INSTANCE_SIGNATURE not set — is Hyprland running?")
	}
	return &Hyprland{}, nil
}

func (h *Hyprland) String() string { return "Hyprland" }

// ── socket paths ──────────────────────────────────────────────────────────────

func hyprSocket1() string {
	sig := os.Getenv("HYPRLAND_INSTANCE_SIGNATURE")
	xdg := os.Getenv("XDG_RUNTIME_DIR")
	if xdg == "" {
		xdg = "/run/user/" + strconv.Itoa(os.Getuid())
	}
	return filepath.Join(xdg, "hypr", sig, ".socket.sock")
}

func hyprSocket2() string {
	sig := os.Getenv("HYPRLAND_INSTANCE_SIGNATURE")
	xdg := os.Getenv("XDG_RUNTIME_DIR")
	if xdg == "" {
		xdg = "/run/user/" + strconv.Itoa(os.Getuid())
	}
	return filepath.Join(xdg, "hypr", sig, ".socket2.sock")
}

// ── low-level helpers ─────────────────────────────────────────────────────────

func hyprctlJSON(args ...string) ([]byte, error) {
	return exec.Command("hyprctl", append(args, "-j")...).Output()
}

func hyprDispatch(cmd string) error {
	conn, err := net.Dial("unix", hyprSocket1())
	if err != nil {
		return err
	}
	defer conn.Close()
	fmt.Fprintf(conn, "dispatch %s", cmd)
	return nil
}

// ── Windows ───────────────────────────────────────────────────────────────────

func (h *Hyprland) ListWindows() ([]Window, error) {
	raw, err := hyprctlJSON("clients")
	if err != nil {
		return nil, err
	}
	var clients []struct {
		Address string `json:"address"`
		Class   string `json:"class"`
		Title   string `json:"title"`
		WS      struct {
			ID int `json:"id"`
		} `json:"workspace"`
		Floating   bool `json:"floating"`
		Fullscreen int  `json:"fullscreen"`
	}
	if err := json.Unmarshal(raw, &clients); err != nil {
		return nil, err
	}

	// Get active window to mark focused
	activeID, _ := h.ActiveWindowID()

	wins := make([]Window, 0, len(clients))
	for _, c := range clients {
		wins = append(wins, Window{
			ID:          c.Address,
			Title:       c.Title,
			Class:       c.Class,
			WorkspaceID: c.WS.ID,
			IsFocused:   c.Address == activeID,
			IsFloating:  c.Floating,
		})
	}
	return wins, nil
}

func (h *Hyprland) ActiveWindowID() (string, error) {
	raw, err := hyprctlJSON("activewindow")
	if err != nil {
		return "", err
	}
	var w struct {
		Address string `json:"address"`
	}
	if err := json.Unmarshal(raw, &w); err != nil {
		return "", err
	}
	return w.Address, nil
}

func (h *Hyprland) FocusWindow(id string) error {
	return hyprDispatch("focuswindow address:" + id)
}

func (h *Hyprland) FocusDir(dir string) error {
	return hyprDispatch("movefocus " + dir)
}

func (h *Hyprland) CloseWindow(id string) error {
	if id == "" {
		return hyprDispatch("killactive")
	}
	return hyprDispatch("closewindow address:" + id)
}

func (h *Hyprland) MoveWindow(id, dir string) error {
	return hyprDispatch("movewindow " + dir)
}

func (h *Hyprland) ResizeWindow(id string, w, hi int) error {
	return hyprDispatch(fmt.Sprintf("resizeactive exact %d %d", w, hi))
}

func (h *Hyprland) ToggleFloating(id string) error {
	return hyprDispatch("togglefloating")
}

func (h *Hyprland) SetFullscreen(id string, on bool) error {
	v := 0
	if on {
		v = 1
	}
	return hyprDispatch(fmt.Sprintf("fullscreen %d", v))
}

// ── Workspaces ────────────────────────────────────────────────────────────────

func (h *Hyprland) ListWorkspaces() ([]Workspace, error) {
	raw, err := hyprctlJSON("workspaces")
	if err != nil {
		return nil, err
	}
	var raw2 []struct {
		ID      int    `json:"id"`
		Name    string `json:"name"`
		Monitor string `json:"monitor"`
		Windows int    `json:"windows"`
	}
	if err := json.Unmarshal(raw, &raw2); err != nil {
		return nil, err
	}

	active, _ := h.ActiveWorkspace()
	activeID := 0
	if active != nil {
		activeID = active.ID
	}

	ws := make([]Workspace, 0, len(raw2))
	for _, w := range raw2 {
		ws = append(ws, Workspace{
			ID:        w.ID,
			Name:      w.Name,
			MonitorID: w.Monitor,
			IsActive:  w.ID == activeID,
			Windows:   w.Windows,
		})
	}
	return ws, nil
}

func (h *Hyprland) ActiveWorkspace() (*Workspace, error) {
	raw, err := hyprctlJSON("activeworkspace")
	if err != nil {
		return nil, err
	}
	var w struct {
		ID      int    `json:"id"`
		Name    string `json:"name"`
		Monitor string `json:"monitor"`
		Windows int    `json:"windows"`
	}
	if err := json.Unmarshal(raw, &w); err != nil {
		return nil, err
	}
	return &Workspace{
		ID:        w.ID,
		Name:      w.Name,
		MonitorID: w.Monitor,
		IsActive:  true,
		Windows:   w.Windows,
	}, nil
}

func (h *Hyprland) SwitchWorkspace(id string) error {
	return hyprDispatch("workspace " + id)
}

func (h *Hyprland) MoveToWorkspace(windowID, wsID string) error {
	return hyprDispatch("movetoworkspace " + wsID)
}

func (h *Hyprland) ToggleSpecialWorkspace(name string) error {
	if name == "" {
		return hyprDispatch("togglespecialworkspace")
	}
	return hyprDispatch("togglespecialworkspace " + name)
}

// ── Monitors ──────────────────────────────────────────────────────────────────

func (h *Hyprland) ListMonitors() ([]Monitor, error) {
	raw, err := hyprctlJSON("monitors")
	if err != nil {
		return nil, err
	}
	var raw2 []struct {
		ID       int     `json:"id"`
		Name     string  `json:"name"`
		Width    int     `json:"width"`
		Height   int     `json:"height"`
		Scale    float64 `json:"scale"`
		Focused  bool    `json:"focused"`
	}
	if err := json.Unmarshal(raw, &raw2); err != nil {
		return nil, err
	}
	ms := make([]Monitor, 0, len(raw2))
	for _, m := range raw2 {
		ms = append(ms, Monitor{
			ID:        strconv.Itoa(m.ID),
			Name:      m.Name,
			Width:     m.Width,
			Height:    m.Height,
			Scale:     m.Scale,
			IsFocused: m.Focused,
		})
	}
	return ms, nil
}

// ── System ────────────────────────────────────────────────────────────────────

func (h *Hyprland) Execute(cmd string) error {
	return hyprDispatch("exec " + cmd)
}

// ── Subscribe (socket2 event stream) ─────────────────────────────────────────

func (h *Hyprland) Subscribe() (<-chan Event, error) {
	conn, err := net.Dial("unix", hyprSocket2())
	if err != nil {
		return nil, err
	}

	ch := make(chan Event, 64)
	go func() {
		defer conn.Close()
		defer close(ch)
		scanner := bufio.NewScanner(conn)
		for scanner.Scan() {
			line := scanner.Text()
			// Format: "eventname>>data"
			parts := strings.SplitN(line, ">>", 2)
			if len(parts) != 2 {
				continue
			}
			name, data := parts[0], parts[1]
			ev := parseHyprEvent(name, data)
			if ev != nil {
				ch <- *ev
			}
		}
	}()
	return ch, nil
}

func parseHyprEvent(name, data string) *Event {
	payload := map[string]interface{}{"raw": data}

	switch name {
	case "openwindow":
		// address,workspacename,class,title
		p := strings.SplitN(data, ",", 4)
		if len(p) >= 4 {
			payload["address"] = "0x" + p[0]
			payload["workspace"] = p[1]
			payload["class"] = p[2]
			payload["title"] = p[3]
		}
		return &Event{Type: EventWindowCreated, Payload: payload}
	case "closewindow":
		payload["address"] = "0x" + data
		return &Event{Type: EventWindowClosed, Payload: payload}
	case "activewindow":
		p := strings.SplitN(data, ",", 2)
		if len(p) == 2 {
			payload["class"] = p[0]
			payload["title"] = p[1]
		}
		return &Event{Type: EventWindowFocused, Payload: payload}
	case "activewindowv2":
		payload["address"] = "0x" + data
		return &Event{Type: EventWindowFocused, Payload: payload}
	case "movewindow":
		p := strings.SplitN(data, ",", 2)
		if len(p) == 2 {
			payload["address"] = "0x" + p[0]
			payload["workspace"] = p[1]
		}
		return &Event{Type: EventWindowMoved, Payload: payload}
	case "workspace", "workspacev2":
		payload["name"] = data
		return &Event{Type: EventWorkspaceChanged, Payload: payload}
	case "monitoradded", "monitorremoved", "focusedmon":
		return &Event{Type: EventMonitorChanged, Payload: payload}
	case "fullscreen":
		payload["fullscreen"] = data == "1"
		return &Event{Type: EventFullscreen, Payload: payload}
	case "changefloatingmode":
		p := strings.SplitN(data, ",", 2)
		if len(p) == 2 {
			payload["address"] = "0x" + p[0]
			payload["floating"] = p[1] == "1"
		}
		return &Event{Type: EventFloating, Payload: payload}
	case "windowtitlev2":
		p := strings.SplitN(data, ",", 2)
		if len(p) == 2 {
			payload["address"] = "0x" + p[0]
			payload["title"] = p[1]
		}
		return &Event{Type: EventWindowTitle, Payload: payload}
	}
	return nil
}
