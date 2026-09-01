#!/usr/bin/env bash

set -u
export PATH="$HOME/.local/bin:$PATH"

missing=0
warnings=0
dotfiles_only=false

case "${1:-}" in
    "") ;;
    --dotfiles-only) dotfiles_only=true ;;
    *) printf 'Uso: %s [--dotfiles-only]\n' "$0" >&2; exit 64 ;;
esac

ok() {
    printf '\033[32mOK\033[0m   %s\n' "$1"
}

fail() {
    printf '\033[31mFALTA\033[0m %s\n' "$1"
    missing=$((missing + 1))
}

warn() {
    printf '\033[33mAVISO\033[0m %s\n' "$1"
    warnings=$((warnings + 1))
}

check_command() {
    local command_name="$1"
    if command -v "$command_name" >/dev/null 2>&1; then
        ok "$command_name"
    else
        fail "$command_name"
    fi
}

if [[ "$dotfiles_only" == false ]]; then
    required_commands=(
        qs hyprctl hyprpaper hyprlauncher hyprshutdown
        wpctl pactl bluetoothctl rfkill nmcli docker docker-compose
        cliphist wl-paste wl-copy grim slurp satty wf-recorder
        brightnessctl ddcutil jq secret-tool kitty zsh eza bat fastfetch zoxide
        ssh ssh-keygen ss ps lspci hyprfm brave zed opencode codex claude hermes
    )

    printf 'Comandos requeridos:\n'
    for command_name in "${required_commands[@]}"; do
        check_command "$command_name"
    done
fi

printf '\nArchivos requeridos:\n'
required_files=(
    "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/minibar/shell.qml"
    "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland.conf"
    "${XDG_CONFIG_HOME:-$HOME/.config}/kitty/kitty.conf"
    "$HOME/.zshrc"
)
for required_file in "${required_files[@]}"; do
    if [[ -f "$required_file" ]]; then
        ok "$required_file"
    else
        fail "$required_file"
    fi
done

if [[ "$dotfiles_only" == false ]]; then
    printf '\nIntegraciones:\n'
    if fc-match 'JetBrainsMono Nerd Font' 2>/dev/null | grep -qi 'JetBrainsMono'; then
        ok 'JetBrainsMono Nerd Font'
    else
        fail 'JetBrainsMono Nerd Font'
    fi

    if docker compose version >/dev/null 2>&1; then
        ok 'docker compose'
    else
        fail 'docker compose'
    fi

    for service in NetworkManager bluetooth docker tailscaled; do
        if systemctl is-enabled "$service.service" >/dev/null 2>&1; then
            ok "servicio $service habilitado"
        else
            warn "servicio $service no está habilitado"
        fi
    done

    if compgen -G '/sys/class/bluetooth/hci*' >/dev/null; then
        ok 'adaptador Bluetooth detectado'
    else
        warn 'esta PC no tiene un adaptador Bluetooth; BlueZ sí quedó instalado'
    fi

    if [[ -s "${XDG_CONFIG_HOME:-$HOME/.config}/nvm/nvm.sh" ]]; then
        ok 'NVM'
    else
        fail 'NVM'
    fi

    for completion_file in \
        "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions/_codex" \
        "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions/_opencode"
    do
        if [[ -s "$completion_file" ]]; then
            ok "autocompletado $(basename "$completion_file")"
        else
            fail "autocompletado $(basename "$completion_file")"
        fi
    done
fi

printf '\nResultado: %d faltante(s), %d aviso(s).\n' "$missing" "$warnings"
(( missing == 0 ))
