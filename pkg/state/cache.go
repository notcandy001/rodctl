package state

import (
	"rodctl/pkg/compositor"
	"sync"
)

// Cache holds the last-known compositor state in memory.
// The daemon updates it on every event so clients never need to re-query.
type Cache struct {
	mu         sync.RWMutex
	windows    []compositor.Window
	workspaces []compositor.Workspace
	monitors   []compositor.Monitor
}

func New() *Cache { return &Cache{} }

// ── Windows ───────────────────────────────────────────────────────────────────

func (c *Cache) SetWindows(ws []compositor.Window) {
	c.mu.Lock()
	c.windows = ws
	c.mu.Unlock()
}

func (c *Cache) GetWindows() []compositor.Window {
	c.mu.RLock()
	defer c.mu.RUnlock()
	out := make([]compositor.Window, len(c.windows))
	copy(out, c.windows)
	return out
}

func (c *Cache) AddWindow(w compositor.Window) {
	c.mu.Lock()
	defer c.mu.Unlock()
	for i, existing := range c.windows {
		if existing.ID == w.ID {
			c.windows[i] = w
			return
		}
	}
	c.windows = append(c.windows, w)
}

func (c *Cache) RemoveWindow(id string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	filtered := c.windows[:0]
	for _, w := range c.windows {
		if w.ID != id {
			filtered = append(filtered, w)
		}
	}
	c.windows = filtered
}

func (c *Cache) MarkFocused(id string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	for i := range c.windows {
		c.windows[i].IsFocused = c.windows[i].ID == id
	}
}

func (c *Cache) UpdateTitle(id, title string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	for i := range c.windows {
		if c.windows[i].ID == id {
			c.windows[i].Title = title
			break
		}
	}
}

func (c *Cache) UpdateWorkspaceForWindow(id string, wsID int) {
	c.mu.Lock()
	defer c.mu.Unlock()
	for i := range c.windows {
		if c.windows[i].ID == id {
			c.windows[i].WorkspaceID = wsID
			break
		}
	}
}

// ── Workspaces ────────────────────────────────────────────────────────────────

func (c *Cache) SetWorkspaces(ws []compositor.Workspace) {
	c.mu.Lock()
	c.workspaces = ws
	c.mu.Unlock()
}

func (c *Cache) GetWorkspaces() []compositor.Workspace {
	c.mu.RLock()
	defer c.mu.RUnlock()
	out := make([]compositor.Workspace, len(c.workspaces))
	copy(out, c.workspaces)
	return out
}

// ── Monitors ──────────────────────────────────────────────────────────────────

func (c *Cache) SetMonitors(ms []compositor.Monitor) {
	c.mu.Lock()
	c.monitors = ms
	c.mu.Unlock()
}

func (c *Cache) GetMonitors() []compositor.Monitor {
	c.mu.RLock()
	defer c.mu.RUnlock()
	out := make([]compositor.Monitor, len(c.monitors))
	copy(out, c.monitors)
	return out
}

// ── Snapshot (sent to new subscribers) ───────────────────────────────────────

type Snapshot struct {
	Windows    []compositor.Window    `json:"windows"`
	Workspaces []compositor.Workspace `json:"workspaces"`
	Monitors   []compositor.Monitor   `json:"monitors"`
}

func (c *Cache) Snapshot() Snapshot {
	c.mu.RLock()
	defer c.mu.RUnlock()
	ws := make([]compositor.Window, len(c.windows))
	copy(ws, c.windows)
	wss := make([]compositor.Workspace, len(c.workspaces))
	copy(wss, c.workspaces)
	ms := make([]compositor.Monitor, len(c.monitors))
	copy(ms, c.monitors)
	return Snapshot{Windows: ws, Workspaces: wss, Monitors: ms}
}
