#!/usr/bin/env bash
set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
monitor_file="$config_dir/monitors.conf"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
current_json="$(hyprctl monitors -j)"

mapfile -t connected_names < <(jq -r 'sort_by(.x) | .[].name' <<<"$current_json")
(( ${#connected_names[@]} > 0 )) || exit 0

ordered_names=()
if [[ -r "$monitor_file" ]]; then
    while IFS= read -r configured_name; do
        if jq -e --arg name "$configured_name" '.[] | select(.name == $name)' <<<"$current_json" >/dev/null; then
            ordered_names+=("$configured_name")
        fi
    done < <(sed -n 's/^[[:space:]]*monitor[[:space:]]*=[[:space:]]*\([^,]*\),.*/\1/p' "$monitor_file")
fi

for connected_name in "${connected_names[@]}"; do
    present=false
    for ordered_name in "${ordered_names[@]}"; do
        [[ "$ordered_name" == "$connected_name" ]] && present=true
    done
    [[ "$present" == false ]] && ordered_names+=("$connected_name")
done

# Reconstruye monitors.conf y workspaces.conf usando el mismo generador que
# el panel de Monitores, para que los espacios locales (1-9 por monitor)
# siempre coincidan con los monitores realmente conectados, en vez de quedar
# atados a un monitor que ya no está presente.
args=(apply)
for monitor_name in "${ordered_names[@]}"; do
    monitor_data="$(jq -c --arg name "$monitor_name" '.[] | select(.name == $name)' <<<"$current_json")"
    width="$(jq -r '.width' <<<"$monitor_data")"
    height="$(jq -r '.height' <<<"$monitor_data")"
    refresh="$(jq -r '.refreshRate' <<<"$monitor_data")"
    scale="$(jq -r '.scale' <<<"$monitor_data")"
    transform="$(jq -r '.transform' <<<"$monitor_data")"
    resolution="${width}x${height}"

    # hyprctl just echoes back whatever mode was last configured, even if it
    # isn't actually one this monitor supports (e.g. a mode left over from a
    # different physical monitor on this same connector). Only trust it if it
    # is really in the monitor's own native mode list; otherwise fall back to
    # its reported native resolution, same as the monitor manager panel does.
    if ! jq -e --arg res "$resolution" '.availableModes | map(select(startswith($res + "@"))) | length > 0' <<<"$monitor_data" >/dev/null; then
        resolution="$(jq -r '.availableModes[0] | sub("@.*"; "")' <<<"$monitor_data")"
        refresh="$(jq -r --arg res "$resolution" '[.availableModes[] | select(startswith($res + "@")) | sub("Hz$"; "") | split("@")[1] | tonumber] | max' <<<"$monitor_data")"
    fi
    mode="${resolution}@$(printf '%.2f' "$refresh")"
    args+=("$monitor_name" "$mode" "$scale" "$transform")
done

bash "$script_dir/monitor-layout.sh" "${args[@]}"
bash "$script_dir/monitor-layout.sh" confirm
