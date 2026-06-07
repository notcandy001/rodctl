package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"strconv"
	"syscall"

	"rodctl/pkg/compositor"
	"rodctl/pkg/server"
)

// ── ANSI ─────────────────────────────────────────────────────────────────────

const (
	reset  = "\033[0m"
	bold   = "\033[1m"
	red    = "\033[31m"
	green  = "\033[32m"
	yellow = "\033[33m"
	cyan   = "\033[36m"
)

func ok(msg string)   { fmt.Fprintf(os.Stdout, "%s%s✓%s  %s\n", bold, green, reset, msg) }
func fail(msg string) { fmt.Fprintf(os.Stderr, "%s%s✗%s  %s\n", bold, red, reset, msg) }
func warn(msg string) { fmt.Fprintf(os.Stderr, "%s%s!%s  %s\n", bold, yellow, reset, msg) }
func info(msg string) { fmt.Fprintf(os.Stdout, "%s%s→%s  %s\n", bold, cyan, reset, msg) }

func die(format string, args ...interface{}) {
	fail(fmt.Sprintf(format, args...))
	os.Exit(1)
}

// ── Entry point ───────────────────────────────────────────────────────────────

func main() {
	if len(os.Args) < 2 {
		printHelp()
		return
	}

	cmd := os.Args[1]
	args := os.Args[2:]

	switch cmd {
	case "daemon":
		runDaemon()
	case "subscribe":
		runSubscribe()

	// compositor / window management — talk to daemon
	case "window":
		if len(args) == 0 { die("Usage: rodctl window <action>") }
		handleWindow(args[0], args[1:])
	case "workspace":
		if len(args) == 0 { die("Usage: rodctl workspace <action>") }
		handleWorkspace(args[0], args[1:])
	case "monitor":
		if len(args) == 0 { die("Usage: rodctl monitor <action>") }
		handleMonitor(args[0], args[1:])

	// CrescentShell IPC — still go through qs
	case "bar":        shell("bar", arg(args, 0, "toggle"))
	case "sidebar":    shell("sidebar"+cap(arg(args, 0, "left")), arg(args, 1, "toggle"))
	case "search":     shell("search", arg(args, 0, "toggle"))
	case "overview":   shell("search", "workspacesToggle")
	case "dashboard":  shell("dashboard", arg(args, 0, "toggle"))
	case "lock":       shell("lock", "activate")
	case "session":    shell("session", arg(args, 0, "toggle"))
	case "cheatsheet": shell("cheatsheet", arg(args, 0, "toggle"))
	case "screenshot": shell("region", arg(args, 0, "screenshot"))
	case "settings":
		settingsPath := os.ExpandEnv("$HOME/.config/quickshell/CrescentShell/settings.qml")
		info("Opening settings…")
		must(exec.Command("qs", "-p", settingsPath).Start())
		ok("Settings launched")

	// Media / hardware — no daemon needed
	case "media":      handleMedia(args)
	case "volume":     handleVolume(args)
	case "brightness": handleBrightness(args)

	// Theme
	case "theme":     handleTheme(args)
	case "wallpaper": shell("wallpaperSelector", arg(args, 0, "toggle"))

	// Shell lifecycle
	case "status":
		if server.IsDaemonRunning() {
			ok("rodctl daemon is running")
		} else {
			fail("rodctl daemon is NOT running")
			os.Exit(1)
		}
	case "start":
		if server.IsDaemonRunning() {
			warn("daemon already running")
		} else {
			info("Starting CrescentShell…")
			must(exec.Command("quickshell", "--config",
				os.ExpandEnv("$HOME/.config/quickshell/CrescentShell")).Start())
			ok("CrescentShell started")
		}
	case "reload":
		must(exec.Command("qs", "reload").Run())
		ok("CrescentShell reloaded")

	case "version":
		fmt.Println("rodctl dev")
	case "help", "--help", "-h":
		printHelp()
	default:
		fail("Unknown command: " + cmd)
		fmt.Fprintf(os.Stderr, "  Run %srodctl help%s for usage.\n", bold, reset)
		os.Exit(1)
	}
}

// ── Daemon ────────────────────────────────────────────────────────────────────

func runDaemon() {
	if server.IsDaemonRunning() {
		die("rodctl daemon is already running")
	}

	comp, err := compositor.NewHyprland()
	if err != nil {
		die("Compositor error: %v", err)
	}
	fmt.Printf("Detected compositor: %s\n", comp)

	socketPath := server.SocketPath()
	srv := server.New(comp, socketPath)
	fmt.Printf("rodctl daemon listening on %s\n", socketPath)

	sig := make(chan os.Signal, 1)
	signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-sig
		os.Remove(socketPath)
		os.Exit(0)
	}()

	if err := srv.Start(); err != nil {
		die("Server error: %v", err)
	}
}

// ── Subscribe ─────────────────────────────────────────────────────────────────

func runSubscribe() {
	conn, err := server.Dial()
	if err != nil {
		die("Cannot connect to daemon: %v", err)
	}
	defer conn.Close()

	json.NewEncoder(conn).Encode(map[string]interface{}{
		"id": 1, "method": "System.Subscribe", "params": map[string]interface{}{},
	})

	scanner := bufio.NewScanner(conn)
	for scanner.Scan() {
		fmt.Println(scanner.Text())
	}
}

// ── Window commands ───────────────────────────────────────────────────────────

func handleWindow(action string, args []string) {
	requireDaemon()
	switch action {
	case "list":
		must(server.RPCprint("Window.List", nil))
	case "active":
		must(server.RPCprint("Window.Active", nil))
	case "focus":
		must(server.RPCprint("Window.Focus", map[string]string{"id": arg(args, 0, "")}))
	case "focus-dir":
		must(server.RPCprint("Window.FocusDir", map[string]string{"dir": arg(args, 0, "l")}))
	case "close":
		must(server.RPCprint("Window.Close", map[string]string{"id": arg(args, 0, "")}))
	case "move":
		must(server.RPCprint("Window.Move", map[string]string{"id": arg(args, 1, ""), "dir": arg(args, 0, "l")}))
	case "resize":
		w, _ := strconv.Atoi(arg(args, 0, "0"))
		h, _ := strconv.Atoi(arg(args, 1, "0"))
		must(server.RPCprint("Window.Resize", map[string]interface{}{"id": arg(args, 2, ""), "w": w, "h": h}))
	case "float", "toggle-float":
		must(server.RPCprint("Window.ToggleFloat", map[string]string{"id": arg(args, 0, "")}))
	case "fullscreen":
		on := arg(args, 0, "1") == "1"
		must(server.RPCprint("Window.Fullscreen", map[string]interface{}{"id": arg(args, 1, ""), "on": on}))
	default:
		die("Unknown window action: %s", action)
	}
}

// ── Workspace commands ────────────────────────────────────────────────────────

func handleWorkspace(action string, args []string) {
	requireDaemon()
	switch action {
	case "list":
		must(server.RPCprint("Workspace.List", nil))
	case "active":
		must(server.RPCprint("Workspace.Active", nil))
	case "switch":
		must(server.RPCprint("Workspace.Switch", map[string]string{"id": arg(args, 0, "")}))
	case "move-to":
		must(server.RPCprint("Workspace.MoveTo", map[string]string{
			"window_id": arg(args, 1, ""),
			"ws_id":     arg(args, 0, ""),
		}))
	case "toggle-special":
		must(server.RPCprint("Workspace.ToggleSpecial", map[string]string{"name": arg(args, 0, "")}))
	default:
		die("Unknown workspace action: %s", action)
	}
}

// ── Monitor commands ──────────────────────────────────────────────────────────

func handleMonitor(action string, args []string) {
	requireDaemon()
	switch action {
	case "list":
		must(server.RPCprint("Monitor.List", nil))
	default:
		die("Unknown monitor action: %s", action)
	}
}

// ── Media ─────────────────────────────────────────────────────────────────────

func handleMedia(args []string) {
	requireDaemon()
	action := arg(args, 0, "")
	switch action {
	case "play-pause": must(server.QsIPC("mpris", "playPause"))
	case "next":       must(server.QsIPC("mpris", "next"))
	case "previous":   must(server.QsIPC("mpris", "previous"))
	case "pause-all":  must(server.QsIPC("mpris", "pauseAll"))
	default:
		die("Usage: rodctl media <play-pause|next|previous|pause-all>")
	}
	info("Media → " + action)
}

// ── Volume ────────────────────────────────────────────────────────────────────

func handleVolume(args []string) {
	switch arg(args, 0, "") {
	case "up":
		must(exec.Command("wpctl", "set-volume", "-l", "1", "@DEFAULT_AUDIO_SINK@", "5%+").Run())
		info("Volume up")
	case "down":
		must(exec.Command("wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-").Run())
		info("Volume down")
	case "mute":
		must(exec.Command("wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle").Run())
		info("Volume mute toggled")
	default:
		die("Usage: rodctl volume <up|down|mute>")
	}
}

// ── Brightness ────────────────────────────────────────────────────────────────

func handleBrightness(args []string) {
	switch arg(args, 0, "") {
	case "up":
		must(exec.Command("brightnessctl", "-e4", "-n2", "set", "5%+").Run())
		info("Brightness up")
	case "down":
		must(exec.Command("brightnessctl", "-e4", "-n2", "set", "5%-").Run())
		info("Brightness down")
	default:
		die("Usage: rodctl brightness <up|down>")
	}
}

// ── Theme ─────────────────────────────────────────────────────────────────────

func handleTheme(args []string) {
	requireDaemon()
	if len(args) == 0 {
		die("Usage: rodctl theme <image>")
	}
	img := args[0]
	if _, err := os.Stat(img); err != nil {
		die("Image not found: %s", img)
	}
	abs, _ := filepath.Abs(img)
	info("Applying theme from: " + abs)
	walset := os.ExpandEnv("$HOME/.local/bin/walset-backend")
	cmd := exec.Command(walset, abs)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	must(cmd.Run())
	ok("Theme applied")
}

// ── Shell IPC helper ──────────────────────────────────────────────────────────

func shell(target, fn string) {
	requireDaemon()
	info(target + " → " + fn)
	if err := server.QsIPC(target, fn); err != nil {
		die("IPC error: %v", err)
	}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

func arg(args []string, i int, def string) string {
	if i < len(args) {
		return args[i]
	}
	return def
}

func cap(s string) string {
	if s == "" {
		return ""
	}
	return string(s[0]-32) + s[1:]
}

func must(err error) {
	if err != nil {
		die("%v", err)
	}
}

func requireDaemon() {
	if !server.IsDaemonRunning() {
		die("rodctl daemon is not running — start it first: rodctl daemon")
	}
}

// ── Help ──────────────────────────────────────────────────────────────────────

func printHelp() {
	fmt.Printf(`
%srodctl%s — CrescentShell controller for Moonveil

%sUSAGE%s
  rodctl <command> [action] [args]

%sDEMON%s
  daemon              Start the daemon (subscribes to Hyprland, caches state)
  subscribe           Stream live events from daemon (JSON-RPC 2.0 notifications)
  status              Check if daemon is running

%sWINDOW%s
  window list                     List all open windows
  window active                   Get active window id
  window focus [id]               Focus a window (default: active)
  window focus-dir <l|r|u|d>      Focus in direction
  window close [id]               Close a window
  window move <dir> [id]          Move window in direction
  window resize <w> <h> [id]      Resize window
  window float [id]               Toggle floating
  window fullscreen <0|1> [id]    Set fullscreen

%sWORKSPACE%s
  workspace list                  List workspaces
  workspace active                Get active workspace
  workspace switch <id>           Switch to workspace
  workspace move-to <ws> [win]    Move window to workspace
  workspace toggle-special [name] Toggle special workspace

%sMONITOR%s
  monitor list                    List monitors

%sCRESCENTSHELL PANELS%s
  bar [toggle|open|close]
  sidebar [left|right] [toggle|open|close]
  search [toggle]
  overview
  dashboard [toggle]
  lock
  session [toggle]
  cheatsheet [toggle]
  screenshot [region|ocr|record|record-sound|full]
  settings

%sMEDIA%s
  media <play-pause|next|previous|pause-all>
  volume <up|down|mute>
  brightness <up|down>

%sTHEME%s
  theme <image>       Apply wallpaper + regenerate matugen colors
  wallpaper [toggle]  Open wallpaper selector

%sNOTE%s
  All compositor and CrescentShell commands require the daemon running.
  Volume and brightness work without it.

`, bold, reset,
		bold, reset,
		bold, reset,
		bold, reset,
		bold, reset,
		bold, reset,
		bold, reset,
		bold, reset,
		bold, reset,
		bold, reset,
		bold, reset)
}
