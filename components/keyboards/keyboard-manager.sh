#!/usr/bin/env bash
set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/minibar"
config_file="$config_dir/keyboards.conf"
state_file="$state_dir/keyboards.json"

mkdir -p "$config_dir" "$state_dir"

bool_value() {
    [[ "$1" == "true" ]] && printf 'true' || printf 'false'
}

case "${1:-}" in
    status)
        if [[ -s "$state_file" ]]; then
            jq -c . "$state_file"
        else
            printf '%s\n' '{"laptop":true,"external":false,"mouseKeyboard":false,"capsMode":"normal"}'
        fi
        exit 0
        ;;
    apply)
        laptop="$(bool_value "${2:-false}")"
        external="$(bool_value "${3:-false}")"
        mouse_keyboard="$(bool_value "${4:-false}")"
        caps_mode="${5:-normal}"
        ;;
    *)
        echo "Uso: $0 status | apply LAPTOP EXTERNO MOUSE CAPS" >&2
        exit 2
        ;;
esac

if [[ "$laptop" != "true" && "$external" != "true" ]]; then
    echo "Debe quedar al menos un teclado físico activo" >&2
    exit 2
fi

if [[ "$caps_mode" != "normal" && "$caps_mode" != "disabled" ]]; then
    echo "Modo de Caps Lock inválido" >&2
    exit 2
fi

config_tmp="$(mktemp "$state_dir/keyboards.conf.XXXXXX")"
state_tmp="$(mktemp "$state_dir/keyboards.json.XXXXXX")"
trap 'rm -f "$config_tmp" "$state_tmp"' EXIT

{
    echo "# Generado por el administrador de teclados de Minibar"
    echo "# Se conserva siempre al menos un teclado físico habilitado."
    echo
    printf 'device {\n    name = at-translated-set-2-keyboard\n    enabled = %s\n}\n\n' "$laptop"

    for device_name in \
        by-tech-gaming-keyboard \
        by-tech-gaming-keyboard-consumer-control \
        by-tech-gaming-keyboard-1 \
        by-tech-gaming-keyboard-system-control
    do
        printf 'device {\n    name = %s\n    enabled = %s\n}\n\n' "$device_name" "$external"
    done

    printf 'device {\n    name = instant-usb-gaming-mouse--keyboard\n    enabled = %s\n}\n\n' "$mouse_keyboard"
    echo "input {"
    if [[ "$caps_mode" == "disabled" ]]; then
        echo "    kb_options = caps:none"
    else
        echo "    kb_options ="
    fi
    echo "}"
} > "$config_tmp"

jq -nc \
    --argjson laptop "$laptop" \
    --argjson external "$external" \
    --argjson mouseKeyboard "$mouse_keyboard" \
    --arg capsMode "$caps_mode" \
    '{laptop:$laptop,external:$external,mouseKeyboard:$mouseKeyboard,capsMode:$capsMode}' \
    > "$state_tmp"

cp -f "$config_tmp" "$config_file"
cp -f "$state_tmp" "$state_file"
hyprctl reload >/dev/null
printf '%s\n' "Configuración aplicada"
