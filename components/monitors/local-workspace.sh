#!/usr/bin/env bash
set -euo pipefail

action="${1:-}"
arg="${2:-}"

if [[ "$action" == "focus-monitor" || "$action" == "move-monitor" ]]; then
    direction="$arg"
    [[ "$direction" == "left" || "$direction" == "right" ]] || exit 2
    short="${direction:0:1}"
    if [[ "$action" == "move-monitor" ]]; then
        hyprctl dispatch movewindow "mon:$short" >/dev/null
    else
        hyprctl dispatch focusmonitor "$short" >/dev/null
    fi
    sleep 0.05
    center="$(hyprctl monitors -j | jq -r '.[] | select(.focused) | [(.x + (.width / .scale / 2) | floor), (.y + (.height / .scale / 2) | floor)] | @tsv')"
    [[ -n "$center" ]] && hyprctl dispatch movecursor ${center//$'\t'/ } >/dev/null
    exit 0
fi

# Espacios locales 1-9: cada monitor tiene su propio bloque de 9, asignado
# por posicion de izquierda a derecha (no por nombre de salida), asi que
# funciona igual sin importar cuantos monitores haya conectados ni en que
# puerto esten. El monitor que cuenta es el que esta bajo el cursor real,
# no el que tiene el foco de teclado (que puede quedarse "pegado" a otra
# pantalla si el escritorio destino esta vacio).
block_size=9
[[ "$arg" =~ ^[1-$block_size]$ ]] || exit 2

monitors="$(hyprctl monitors -j)"
cursor="$(hyprctl cursorpos -j)"

monitor="$(jq -r --argjson c "$cursor" '
    ($c.x) as $cx | ($c.y) as $cy |
    .[] |
    (((.transform % 2) == 1)) as $rot |
    ((if $rot then .height else .width end) / .scale) as $lw |
    ((if $rot then .width else .height end) / .scale) as $lh |
    select(.x <= $cx and $cx < (.x + $lw) and .y <= $cy and $cy < (.y + $lh)) |
    .name
' <<< "$monitors")"
[[ -n "$monitor" ]] || { echo "No se detecto ningun monitor bajo el cursor" >&2; exit 1; }

mapfile -t sorted_names < <(jq -r 'sort_by(.x) | .[].name' <<< "$monitors")
index=-1
for i in "${!sorted_names[@]}"; do
    [[ "${sorted_names[$i]}" == "$monitor" ]] && { index=$i; break; }
done
[[ $index -ge 0 ]] || { echo "No se pudo ubicar $monitor en la lista de monitores" >&2; exit 1; }

target=$(( index * block_size + arg ))

case "$action" in
    switch) hyprctl dispatch workspace "$target" >/dev/null ;;
    move) hyprctl dispatch movetoworkspace "$target" >/dev/null ;;
    *) exit 2 ;;
esac
