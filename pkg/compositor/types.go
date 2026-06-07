package compositor

// Window represents an open window.
type Window struct {
	ID          string `json:"id"`
	Title       string `json:"title"`
	Class       string `json:"class"`
	WorkspaceID int    `json:"workspace_id"`
	IsFocused   bool   `json:"is_focused"`
	IsFloating  bool   `json:"is_floating"`
}

// Workspace represents a compositor workspace.
type Workspace struct {
	ID        int    `json:"id"`
	Name      string `json:"name"`
	MonitorID string `json:"monitor_id"`
	IsActive  bool   `json:"is_active"`
	Windows   int    `json:"windows"`
}

// Monitor represents an output monitor.
type Monitor struct {
	ID        string  `json:"id"`
	Name      string  `json:"name"`
	Width     int     `json:"width"`
	Height    int     `json:"height"`
	Scale     float64 `json:"scale"`
	IsFocused bool    `json:"is_focused"`
}

// EventType is what happened in the compositor.
type EventType string

const (
	EventWindowCreated    EventType = "window_created"
	EventWindowClosed     EventType = "window_closed"
	EventWindowFocused    EventType = "window_focused"
	EventWindowMoved      EventType = "window_moved"
	EventWindowTitle      EventType = "window_title"
	EventWorkspaceChanged EventType = "workspace_changed"
	EventMonitorChanged   EventType = "monitor_changed"
	EventFullscreen       EventType = "fullscreen_changed"
	EventFloating         EventType = "floating_changed"
)

// Event is an event from the compositor event stream.
type Event struct {
	Type    EventType              `json:"type"`
	Payload map[string]interface{} `json:"payload,omitempty"`
}

// Compositor is the abstract interface rodctl's daemon uses.
// Only Hyprland is implemented, but the architecture is clean.
type Compositor interface {
	// Windows
	ListWindows() ([]Window, error)
	ActiveWindowID() (string, error)
	FocusWindow(id string) error
	FocusDir(dir string) error
	CloseWindow(id string) error
	MoveWindow(id, dir string) error
	ResizeWindow(id string, w, h int) error
	ToggleFloating(id string) error
	SetFullscreen(id string, on bool) error

	// Workspaces
	ListWorkspaces() ([]Workspace, error)
	ActiveWorkspace() (*Workspace, error)
	SwitchWorkspace(id string) error
	MoveToWorkspace(windowID, wsID string) error
	ToggleSpecialWorkspace(name string) error

	// Monitors
	ListMonitors() ([]Monitor, error)

	// System
	Execute(cmd string) error
	Subscribe() (<-chan Event, error)
}
