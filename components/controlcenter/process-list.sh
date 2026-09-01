#!/usr/bin/env bash

set -o pipefail

# Emit one TSV row per process, augmented with the application group inferred
# from its process tree. The UI performs the aggregation so it can preserve the
# individual PIDs for the expandable detail view.
LC_ALL=C ps -u "$(id -u)" \
    -o pid=,ppid=,comm=,%cpu=,%mem=,rss=,args= --sort=pid |
awk -v self_pid="$$" '
function is_boundary(name) {
    return name == "systemd" || name == "(sd-pam)" ||
           name == "Hyprland" || name == "start-hyprland" ||
           name == "uwsm" || name == "uwsm-app" ||
           name == "dbus-broker"
}

function belongs_to_helper(pid, current, depth) {
    current = pid
    for (depth = 0; depth < 64 && current in parent; depth++) {
        if (current == self_pid)
            return 1
        current = parent[current]
    }
    return 0
}

function application_root(pid, current, ancestor, depth) {
    current = pid
    for (depth = 0; depth < 64; depth++) {
        ancestor = parent[current]
        if (!(ancestor in command) || is_boundary(command[ancestor]))
            break
        current = ancestor
    }
    return current
}

function family_for(root, value, name) {
    name = tolower(command[root])
    value = tolower(command[root] " " arguments[root])

    if (index(value, "brave") || name == "chrome_crashpad") return "brave"
    if (name == "zed-editor" || index(value, "/zed/") || index(value, "zed-cli")) return "zed"
    if (index(value, "datagrip")) return "datagrip"
    if (index(value, "obsidian")) return "obsidian"
    if (name == "qs" || name == "quickshell") return "quickshell"
    if (name == "kitty") return "kitty"
    if (name == "firefox") return "firefox"
    if (name == "nautilus") return "nautilus"
    if (name == "dolphin") return "dolphin"
    if (name == "thunar") return "thunar"
    if (name == "postman") return "postman"
    if (name == "discord") return "discord"
    if (name == "spotify") return "spotify"
    if (name == "steam" || name == "steamwebhelper") return "steam"
    if (name == "code" || name == "code-insiders") return "vscode"
    if (index(value, "idea") || index(value, "intellij")) return "intellij"
    if (index(value, "pycharm")) return "pycharm"
    if (index(value, "webstorm")) return "webstorm"
    if (name == "jetbrainsd") return "jetbrains-service"

    # Interpreters and shells may host unrelated applications, so keep those
    # roots isolated. Native programs with the same executable are one group.
    if (name == "bash" || name == "sh" || name == "zsh" ||
        name == "fish" || name == "node" || name == "python" ||
        name == "python3" || name == "java" || name == "electron" ||
        name == "mainthread")
        return "root:" root

    return "app:" name
}

function label_for(family, root, name) {
    if (family == "brave") return "Brave"
    if (family == "zed") return "Zed"
    if (family == "datagrip") return "DataGrip"
    if (family == "obsidian") return "Obsidian"
    if (family == "quickshell") return "Quickshell"
    if (family == "kitty") return "Kitty"
    if (family == "firefox") return "Firefox"
    if (family == "nautilus") return "Archivos (Nautilus)"
    if (family == "dolphin") return "Dolphin"
    if (family == "thunar") return "Thunar"
    if (family == "postman") return "Postman"
    if (family == "discord") return "Discord"
    if (family == "spotify") return "Spotify"
    if (family == "steam") return "Steam"
    if (family == "vscode") return "Visual Studio Code"
    if (family == "intellij") return "IntelliJ IDEA"
    if (family == "pycharm") return "PyCharm"
    if (family == "webstorm") return "WebStorm"
    if (family == "jetbrains-service") return "Servicio de JetBrains"

    name = command[root]
    if (name == "java") return "Java"
    if (name == "python" || name == "python3") return "Python"
    if (name == "node") return "Node.js"
    if (name == "electron") return "Electron"
    return name
}

function detail_for(pid, value, start, role) {
    value = arguments[pid]

    if (command[pid] == "chrome_crashpad") return "Informes de fallos"
    if (command[pid] == "brave") {
        start = index(value, "--type=")
        if (!start) return "Proceso principal"
        role = substr(value, start + 7)
        sub(/[ ].*$/, "", role)
        if (role == "renderer") return "Renderizador de pestaña"
        if (role == "gpu-process") return "Aceleración gráfica"
        if (role == "utility") return "Servicio auxiliar"
        if (role == "zygote") return "Creador de procesos"
        return role
    }
    if (command[pid] == "MainThread") {
        if (index(value, "codex-acp/dist")) return "Codex ACP"
        if (index(value, "@openai/codex/bin")) return "Servidor Codex"
        return "Node.js"
    }
    if (command[pid] == "codex") return "Servidor Codex"
    if (command[pid] == "codex-code-mode") return "Herramientas Codex"
    if (command[pid] == "fsnotifier") return "Vigilancia de archivos"
    if (command[pid] == "java" && index(tolower(value), "datagrip")) return "Java / JDBC"
    if (command[pid] == "qs") {
        if (index(value, "-c minibar")) return "Minibar"
        if (index(value, "-c overview")) return "Overview"
    }
    return "Proceso vinculado"
}

{
    pid = $1
    parent[pid] = $2
    command[pid] = $3
    cpu[pid] = $4
    memory[pid] = $5
    rss[pid] = $6

    args = ""
    for (i = 7; i <= NF; i++)
        args = args (i == 7 ? "" : " ") $i
    arguments[pid] = args
    order[++count] = pid
}

END {
    for (i = 1; i <= count; i++) {
        pid = order[i]
        if (belongs_to_helper(pid))
            continue

        root = application_root(pid)
        family = family_for(root)
        label = label_for(family, root)
        detail = detail_for(pid)
        printf "%s\t%s\t%d\t%d\t%d\t%s\t%.2f\t%.2f\t%d\t%s\n", \
            family, label, root, pid, parent[pid], command[pid], \
            cpu[pid] + 0, memory[pid] + 0, rss[pid] + 0, detail
    }
}
'
