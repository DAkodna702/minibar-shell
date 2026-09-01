#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'
export PATH="$HOME/.local/bin:$PATH"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XDG_CONFIG_HOME_VALUE="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE_HOME_VALUE="${XDG_STATE_HOME:-$HOME/.local/state}"
MINIBAR_DIR="$XDG_CONFIG_HOME_VALUE/quickshell/minibar"
BACKUP_DIR="$XDG_STATE_HOME_VALUE/minibar-installer/backups/$(date +'%Y%m%d-%H%M%S')"
TEMP_ROOT="$(mktemp -d)"
DOTFILES_ONLY=false
BACKUP_CREATED=false

cleanup() {
    rm -rf -- "$TEMP_ROOT"
}

on_error() {
    local exit_code=$?
    printf '\nError en la línea %s. La instalación se detuvo (código %s).\n' \
        "${BASH_LINENO[0]}" "$exit_code" >&2
    if [[ "$BACKUP_CREATED" == true ]]; then
        printf 'Tus copias anteriores están en: %s\n' "$BACKUP_DIR" >&2
    fi
    exit "$exit_code"
}

trap cleanup EXIT
trap on_error ERR

usage() {
    cat <<'EOF'
Uso: ./install.sh [opción]

Sin opciones instala el escritorio, aplicaciones, servicios y dotfiles.

  --dotfiles-only   Solo instala Minibar y las configuraciones del usuario.
  -h, --help        Muestra esta ayuda.
EOF
}

for argument in "$@"; do
    case "$argument" in
        --dotfiles-only) DOTFILES_ONLY=true ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Opción desconocida: %s\n' "$argument" >&2; usage; exit 64 ;;
    esac
done

if (( EUID == 0 )); then
    printf 'Ejecuta este instalador como tu usuario normal, no como root.\n' >&2
    exit 1
fi

log() {
    printf '\n\033[1;36m==> %s\033[0m\n' "$*"
}

read_manifest() {
    sed -E '/^[[:space:]]*(#|$)/d' "$1"
}

assert_arch() {
    # shellcheck disable=SC1091
    source /etc/os-release
    if [[ "${ID:-}" != "arch" && "${ID_LIKE:-}" != *arch* ]]; then
        printf 'Este instalador completo requiere Arch Linux o una derivada. Detectado: %s\n' \
            "${PRETTY_NAME:-desconocido}" >&2
        printf 'Puedes usar ./install.sh --dotfiles-only en otra distribución.\n' >&2
        exit 1
    fi
    command -v pacman >/dev/null 2>&1 || {
        printf 'No se encontró pacman.\n' >&2
        exit 1
    }
}

install_arch_packages() {
    local packages=()
    mapfile -t packages < <(read_manifest "$REPO_DIR/packages/arch.txt")
    log "Actualizando Arch e instalando ${#packages[@]} paquetes oficiales"
    sudo pacman -Syu --needed "${packages[@]}"
}

install_aur_package() {
    local package="$1"
    local build_dir

    if pacman -Q "$package" >/dev/null 2>&1; then
        printf 'AUR listo: %s\n' "$package"
        return
    fi

    if command -v paru >/dev/null 2>&1; then
        paru -S --needed "$package"
        return
    fi

    if command -v yay >/dev/null 2>&1; then
        yay -S --needed "$package"
        return
    fi

    build_dir="$TEMP_ROOT/aur-$package"
    git clone "https://aur.archlinux.org/$package.git" "$build_dir"
    (
        cd "$build_dir"
        makepkg -si --needed
    )
}

install_aur_packages() {
    local packages=()
    mapfile -t packages < <(read_manifest "$REPO_DIR/packages/aur.txt")
    log "Instalando paquetes de AUR"
    for package in "${packages[@]}"; do
        install_aur_package "$package"
    done
}

run_remote_installer() {
    local name="$1"
    local url="$2"
    local interpreter="$3"
    local installer="$TEMP_ROOT/${name// /-}.sh"
    shift 3

    printf 'Instalando o actualizando %s...\n' "$name"
    curl -fsSL "$url" -o "$installer"
    "$interpreter" "$installer" "$@"
}

install_official_apps() {
    log "Instalando aplicaciones desde sus instaladores oficiales"
    run_remote_installer "Zed" "https://zed.dev/install.sh" sh
    run_remote_installer "Codex" "https://chatgpt.com/codex/install.sh" sh
    run_remote_installer "Claude-Code" "https://claude.ai/install.sh" bash
    run_remote_installer \
        "Hermes-Agent" \
        "https://hermes-agent.nousresearch.com/install.sh" \
        bash --skip-setup --skip-browser --skip-computer-use --non-interactive
}

install_shell_completions() {
    local completion_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions"
    local temporary_completion

    log "Generando autocompletado de Codex y OpenCode para Zsh"
    mkdir -p "$completion_dir"

    temporary_completion="$TEMP_ROOT/_codex"
    codex completion zsh > "$temporary_completion"
    install -m644 "$temporary_completion" "$completion_dir/_codex"

    temporary_completion="$TEMP_ROOT/_opencode"
    opencode completion zsh > "$temporary_completion"
    install -m644 "$temporary_completion" "$completion_dir/_opencode"
}

install_nvm_and_node() {
    local nvm_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvm"
    local latest_tag

    log "Instalando NVM y la versión LTS de Node.js"
    if [[ ! -d "$nvm_dir/.git" ]]; then
        if [[ -e "$nvm_dir" ]]; then
            printf '%s existe, pero no es un repositorio de NVM. No se sobrescribirá.\n' \
                "$nvm_dir" >&2
            return 1
        fi
        git clone https://github.com/nvm-sh/nvm.git "$nvm_dir"
    else
        git -C "$nvm_dir" fetch --tags --prune origin
    fi

    latest_tag="$(git -C "$nvm_dir" tag --sort=-version:refname | sed -n '1p')"
    [[ -n "$latest_tag" ]] || {
        printf 'No se pudo determinar la última versión estable de NVM.\n' >&2
        return 1
    }
    git -C "$nvm_dir" checkout --quiet "$latest_tag"

    set +u
    # shellcheck disable=SC1091
    source "$nvm_dir/nvm.sh"
    nvm install --lts
    nvm alias default 'lts/*'
    set -u
}

backup_path() {
    local target="$1"
    local relative safe_name

    [[ -e "$target" || -L "$target" ]] || return 0
    relative="${target#"$HOME"/}"
    safe_name="${relative//\//__}"
    mkdir -p "$BACKUP_DIR"
    cp -a -- "$target" "$BACKUP_DIR/$safe_name"
    BACKUP_CREATED=true
}

deploy_file() {
    local source_file="$1"
    local target_file="$2"
    local mode="${3:-644}"

    backup_path "$target_file"
    install -Dm"$mode" "$source_file" "$target_file"
}

deploy_minibar() {
    local source_real target_real
    source_real="$(readlink -f "$REPO_DIR")"
    target_real="$(readlink -m "$MINIBAR_DIR")"

    if [[ "$source_real" == "$target_real" ]]; then
        printf 'El repositorio ya está en %s; se conservará en su lugar.\n' "$MINIBAR_DIR"
    else
        backup_path "$MINIBAR_DIR"
        if [[ "$target_real" != "$XDG_CONFIG_HOME_VALUE/quickshell/minibar" ]]; then
            printf 'Ruta de destino inesperada: %s\n' "$target_real" >&2
            return 1
        fi
        rm -rf -- "$target_real"
        mkdir -p "$target_real"
        install -m644 "$REPO_DIR/shell.qml" "$target_real/shell.qml"
        cp -a "$REPO_DIR/components" "$target_real/components"
    fi

    find "$MINIBAR_DIR/components" -type f -name '*.sh' -exec chmod 755 {} +
}

deploy_dotfiles() {
    log "Instalando Minibar y dotfiles con copias de seguridad"
    deploy_minibar

    deploy_file "$REPO_DIR/dotfiles/hypr/hyprland.conf" \
        "$XDG_CONFIG_HOME_VALUE/hypr/hyprland.conf"
    deploy_file "$REPO_DIR/dotfiles/hypr/hyprpaper.conf" \
        "$XDG_CONFIG_HOME_VALUE/hypr/hyprpaper.conf"
    deploy_file "$REPO_DIR/dotfiles/hypr/monitors.conf" \
        "$XDG_CONFIG_HOME_VALUE/hypr/monitors.conf"
    deploy_file "$REPO_DIR/dotfiles/hypr/workspaces.conf" \
        "$XDG_CONFIG_HOME_VALUE/hypr/workspaces.conf"
    deploy_file "$REPO_DIR/dotfiles/hypr/keyboards.conf" \
        "$XDG_CONFIG_HOME_VALUE/hypr/keyboards.conf"
    deploy_file "$REPO_DIR/dotfiles/kitty/kitty.conf" \
        "$XDG_CONFIG_HOME_VALUE/kitty/kitty.conf"
    deploy_file "$REPO_DIR/dotfiles/quickshell/overview/config.json" \
        "$XDG_CONFIG_HOME_VALUE/quickshell/overview/config.json"
    deploy_file "$REPO_DIR/dotfiles/zsh/.zshrc" "$HOME/.zshrc"

    command -v xdg-user-dirs-update >/dev/null 2>&1 && xdg-user-dirs-update
    mkdir -p \
        "$HOME/Pictures/Screenshots" \
        "$HOME/Videos/Recordings" \
        "$HOME/wallparpers" \
        "$HOME/.local/bin"

    command -v fc-cache >/dev/null 2>&1 && fc-cache -f
}

configure_services() {
    log "Habilitando servicios de red, Bluetooth, Docker y Tailscale"
    sudo systemctl enable --now NetworkManager.service
    sudo systemctl enable bluetooth.service
    if compgen -G '/sys/class/bluetooth/hci*' >/dev/null; then
        sudo systemctl start bluetooth.service
    else
        printf 'No se detectó un adaptador Bluetooth; BlueZ quedó instalado y habilitado.\n'
    fi
    sudo systemctl enable --now docker.service
    sudo systemctl enable --now tailscaled.service

    if ! id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
        sudo usermod -aG docker "$USER"
        printf 'Se añadió %s al grupo docker; se aplicará al volver a iniciar sesión.\n' "$USER"
    fi

    if getent group i2c >/dev/null 2>&1 \
        && ! id -nG "$USER" | tr ' ' '\n' | grep -qx i2c
    then
        sudo usermod -aG i2c "$USER"
        printf 'Se añadió %s al grupo i2c para controlar monitores externos.\n' "$USER"
    fi

    sudo tailscale set --operator="$USER" >/dev/null 2>&1 || \
        printf 'Tailscale está instalado; ejecuta "tailscale up" después para iniciar sesión.\n'

    systemctl --user enable \
        pipewire.socket pipewire-pulse.socket wireplumber.service hyprpaper.service \
        >/dev/null 2>&1 || true
    systemctl --user start \
        pipewire.socket pipewire-pulse.socket wireplumber.service hyprpaper.service \
        >/dev/null 2>&1 || true
}

configure_defaults() {
    local zsh_path current_shell desktop_file=""

    log "Configurando Zsh y HyprFM como valores predeterminados"
    zsh_path="$(command -v zsh)"
    current_shell="$(getent passwd "$USER" | cut -d: -f7)"
    if [[ "$current_shell" != "$zsh_path" ]]; then
        sudo chsh -s "$zsh_path" "$USER"
    fi

    for candidate in \
        /usr/share/applications/hyprfm.desktop \
        /usr/share/applications/io.github.soyeb_jim285.HyprFM.desktop \
        "$HOME/.local/share/applications/hyprfm.desktop" \
        "$HOME/.local/share/applications/io.github.soyeb_jim285.HyprFM.desktop"
    do
        if [[ -f "$candidate" ]]; then
            desktop_file="$(basename "$candidate")"
            break
        fi
    done

    if [[ -n "$desktop_file" ]]; then
        xdg-mime default "$desktop_file" inode/directory
    else
        printf 'No se encontró el .desktop de HyprFM; SUPER+E sí usará hyprfm.\n'
    fi
}

refresh_running_hyprland() {
    if command -v hyprctl >/dev/null 2>&1 && hyprctl monitors -j >/dev/null 2>&1; then
        log "Detectando las pantallas de esta PC y recargando Hyprland"
        bash "$MINIBAR_DIR/components/monitors/monitor-hotplug.sh"
    fi
}

main() {
    if [[ "$DOTFILES_ONLY" == false ]]; then
        assert_arch
        sudo -v
        install_arch_packages
        install_aur_packages
        install_official_apps
        install_shell_completions
        install_nvm_and_node
    fi

    deploy_dotfiles

    if [[ "$DOTFILES_ONLY" == false ]]; then
        configure_services
        configure_defaults
    fi

    refresh_running_hyprland

    log "Verificando la instalación"
    local check_args=()
    [[ "$DOTFILES_ONLY" == true ]] && check_args+=(--dotfiles-only)
    if "$REPO_DIR/scripts/check-dependencies.sh" "${check_args[@]}"; then
        printf '\nInstalación terminada correctamente.\n'
    else
        printf '\nLa instalación terminó, pero el verificador encontró faltantes.\n' >&2
        exit 1
    fi

    if [[ "$BACKUP_CREATED" == true ]]; then
        printf 'Copias de seguridad: %s\n' "$BACKUP_DIR"
    fi
    if [[ "$DOTFILES_ONLY" == false ]]; then
        printf 'Cierra sesión y vuelve a entrar para aplicar Zsh y los grupos docker/i2c.\n'
        printf 'Después ejecuta: tailscale up, codex, claude, opencode y hermes setup.\n'
    fi
}

main
