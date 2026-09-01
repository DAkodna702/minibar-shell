#!/usr/bin/env bash

set -u

hermes_bin="${HERMES_BIN:-$HOME/.local/bin/hermes}"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/minibar/hermes"
log_file="$state_dir/gateway.log"

is_running() {
    "$hermes_bin" gateway status 2>&1 | grep -q "Gateway is running"
}

print_last_error() {
    if [[ -s "$log_file" ]]; then
        tail -n 1 "$log_file" | sed -E 's/\x1B\[[0-9;]*[[:alpha:]]//g'
    else
        printf '%s\n' "Hermes no pudo iniciar"
    fi
}

case "${1:-status}" in
    status)
        if is_running; then
            printf '%s\n' "running"
        else
            printf '%s\n' "stopped"
        fi
        ;;
    start)
        if [[ ! -x "$hermes_bin" ]]; then
            printf '%s\n' "No se encontró Hermes Agent" >&2
            exit 1
        fi
        if is_running; then
            printf '%s\n' "running"
            exit 0
        fi

        mkdir -p "$state_dir"
        : > "$log_file"
        nohup "$hermes_bin" gateway run --quiet </dev/null >>"$log_file" 2>&1 &
        launcher_pid=$!

        for _ in {1..24}; do
            if is_running; then
                printf '%s\n' "running"
                exit 0
            fi
            if ! kill -0 "$launcher_pid" 2>/dev/null; then
                print_last_error >&2
                exit 1
            fi
            sleep 0.25
        done

        printf '%s\n' "Hermes tardó demasiado en iniciar" >&2
        exit 1
        ;;
    stop)
        if ! is_running; then
            printf '%s\n' "stopped"
            exit 0
        fi

        if ! "$hermes_bin" gateway stop >/dev/null 2>&1; then
            printf '%s\n' "No se pudo detener Hermes Agent" >&2
            exit 1
        fi

        for _ in {1..24}; do
            if ! is_running; then
                printf '%s\n' "stopped"
                exit 0
            fi
            sleep 0.25
        done

        printf '%s\n' "Hermes no respondió a la orden de apagado" >&2
        exit 1
        ;;
    toggle)
        if is_running; then
            exec "$0" stop
        else
            exec "$0" start
        fi
        ;;
    log)
        mkdir -p "$state_dir"
        touch "$log_file"
        printf '%s\n' "$log_file"
        ;;
    *)
        printf 'Uso: %s {status|start|stop|toggle|log}\n' "$0" >&2
        exit 2
        ;;
esac
