#!/usr/bin/env bash
set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/minibar/monitors"
monitor_file="$config_dir/monitors.conf"
workspace_file="$config_dir/workspaces.conf"
pending_file="$state_dir/pending"
backup_monitor="$state_dir/monitors.backup"
backup_workspace="$state_dir/workspaces.backup"

mkdir -p "$config_dir" "$state_dir"

restore_files() {
    [[ -f "$backup_monitor" ]] && cp -f "$backup_monitor" "$monitor_file"
    [[ -f "$backup_workspace" ]] && cp -f "$backup_workspace" "$workspace_file"
    rm -f "$pending_file" "$backup_monitor" "$backup_workspace"
    hyprctl reload >/dev/null 2>&1 || true
}

case "${1:-}" in
    confirm)
        rm -f "$pending_file" "$backup_monitor" "$backup_workspace"
        exit 0
        ;;
    revert)
        restore_files
        exit 0
        ;;
    rollback-if-pending)
        token="${2:-}"
        sleep 15
        if [[ -f "$pending_file" ]] && [[ "$(<"$pending_file")" == "$token" ]]; then
            restore_files
        fi
        exit 0
        ;;
    apply)
        shift
        ;;
    *)
        echo "Uso: $0 apply MONITOR MODO ESCALA TRANSFORM [...] | confirm | revert" >&2
        exit 2
        ;;
esac

if (( $# < 4 || $# % 4 != 0 )); then
    echo "Faltan grupos MONITOR/MODO/ESCALA/TRANSFORM" >&2
    exit 2
fi

[[ -f "$monitor_file" ]] && cp -f "$monitor_file" "$backup_monitor" || : > "$backup_monitor"
[[ -f "$workspace_file" ]] && cp -f "$workspace_file" "$backup_workspace" || : > "$backup_workspace"

names=()
modes=()
transforms=()
scales=()
max_height=0
while (( $# )); do
    name="$1"
    mode="$2"
    scale="$3"
    transform="$4"
    shift 4
    [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "Conector inválido" >&2; exit 2; }
    [[ "$mode" =~ ^[0-9]+x[0-9]+@[0-9.]+$ ]] || { echo "Modo inválido" >&2; exit 2; }
    [[ "$scale" =~ ^(1|1\.25|1\.5|1\.75|2)$ ]] || { echo "Escala inválida" >&2; exit 2; }
    [[ "$transform" =~ ^[0-3]$ ]] || { echo "Orientación inválida" >&2; exit 2; }
    names+=("$name")
    modes+=("$mode")
    scales+=("$scale")
    transforms+=("$transform")
    width="${mode%%x*}"
    height="${mode#*x}"; height="${height%@*}"
    if (( transform == 1 || transform == 3 )); then
        footprint_height="$width"
    else
        footprint_height="$height"
    fi
    logical_height="$(awk -v pixels="$footprint_height" -v factor="$scale" 'BEGIN { printf "%d", pixels / factor + 0.5 }')"
    (( logical_height > max_height )) && max_height="$logical_height"
done

monitor_tmp="$(mktemp "$state_dir/monitors.XXXXXX")"
workspace_tmp="$(mktemp "$state_dir/workspaces.XXXXXX")"
trap 'rm -f "$monitor_tmp" "$workspace_tmp"' EXIT

{
    echo "# Generado por el administrador de monitores de Minibar"
    x=0
    for i in "${!names[@]}"; do
        mode="${modes[$i]}"
        scale="${scales[$i]}"
        transform="${transforms[$i]}"
        width="${mode%%x*}"
        height="${mode#*x}"; height="${height%@*}"
        if (( transform == 1 || transform == 3 )); then
            footprint_width="$height"
            footprint_height="$width"
        else
            footprint_width="$width"
            footprint_height="$height"
        fi
        logical_width="$(awk -v pixels="$footprint_width" -v factor="$scale" 'BEGIN { printf "%d", pixels / factor + 0.5 }')"
        logical_height="$(awk -v pixels="$footprint_height" -v factor="$scale" 'BEGIN { printf "%d", pixels / factor + 0.5 }')"
        y=$(( (max_height - logical_height) / 2 ))
        printf 'monitor = %s,%s,%sx%s,%s,transform,%s\n' "${names[$i]}" "$mode" "$x" "$y" "$scale" "$transform"
        x=$((x + logical_width))
    done
} > "$monitor_tmp"

{
    echo "# Nueve espacios locales por monitor, de izquierda a derecha"
    for i in "${!names[@]}"; do
        first=$((i * 9 + 1))
        for offset in 0 1 2 3 4 5 6 7 8; do
            workspace=$((first + offset))
            default=""
            (( offset == 0 )) && default=", default:true"
            printf 'workspace = %s, monitor:%s, persistent:true%s\n' "$workspace" "${names[$i]}" "$default"
        done
    done
} > "$workspace_tmp"

cp -f "$monitor_tmp" "$monitor_file"
cp -f "$workspace_tmp" "$workspace_file"
token="$(date +%s%N)-$$"
printf '%s' "$token" > "$pending_file"

if ! hyprctl reload >/dev/null; then
    restore_files
    echo "Hyprland rechazó la configuración" >&2
    exit 1
fi

nohup "$0" rollback-if-pending "$token" >/dev/null 2>&1 &
printf '%s\n' "$token"
