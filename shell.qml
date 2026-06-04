import QtQuick
import Quickshell
import "modules/bar"
import "modules/settings"
import "services"

ShellRoot {
    // Singletons instantiated by Quickshell automatically via qmldir
    Bar { }
}
