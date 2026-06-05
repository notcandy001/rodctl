import QtQuick
import Quickshell
import "modules/bar"
import "modules/settings"
import "services"
import "theme"

ShellRoot {
    // All singletons (Colors, ThemeService, BarSettings, NetworkInfo, SettingsWindow)
    // are auto-instantiated by Quickshell via their respective qmldir files.
    Bar { }
}
