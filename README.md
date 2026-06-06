# rodctl

A Go CLI controller for **CrescentShell** (Moonveil's Quickshell UI).

Every command (except `status` and `start`) checks if CrescentShell is actually running before doing anything. If it's not up, you get a clean error instead of a silent 

## Commands

### Shell lifecycle
```bash
rodctl status          # is CrescentShell running?
rodctl start           # launch it
rodctl reload          # hot-reload
```

### UI panels
```bash
rodctl bar [toggle|open|close]
rodctl sidebar left [toggle|open|close]
rodctl sidebar right [toggle|open|close]
rodctl dashboard [toggle|open|close]
rodctl overlay
rodctl panel cycle
```

### App launcher & workspaces
```bash
rodctl search          # app launcher / search toggle
rodctl workspaces      # workspace overview toggle
rodctl overview        # overview widget toggle
```

### Screen & session
```bash
rodctl lock
rodctl session [toggle|open|close]
rodctl settings
rodctl cheatsheet
rodctl screenshot region
rodctl screenshot full
rodctl screenshot ocr
rodctl screenshot record
rodctl screenshot record-sound
```

### Media & hardware
```bash
rodctl media play-pause
rodctl media next
rodctl media previous
rodctl media pause-all
rodctl volume up
rodctl volume down
rodctl volume mute
rodctl brightness up
rodctl brightness 
```

