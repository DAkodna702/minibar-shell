#!/usr/bin/env bash

set -u

action="${1:-status}"

status_line() {
    if ! command -v tailscale >/dev/null 2>&1; then
        printf '0\t0\tNotInstalled\t0\t\t\t\t0\t0\n'
        return
    fi

    if ! systemctl is-active --quiet tailscaled; then
        printf '1\t0\tDaemonStopped\t0\t\t\t\t0\t0\n'
        return
    fi

    local status_json status_fields
    status_json="$(tailscale status --json 2>/dev/null || true)"

    if [[ -z "$status_json" ]]; then
        printf '1\t1\tUnknown\t0\t\t\t\t0\t0\n'
        return
    fi

    status_fields="$(
        jq -r '[
            (.BackendState // "Unknown"),
            ((.Self.Online // false) | if . then "1" else "0" end),
            (.Self.HostName // ""),
            ((.Self.TailscaleIPs // [])[0] // ""),
            (.CurrentTailnet.Name // ""),
            (((.Peer // {}) | length) | tostring),
            (([(.Peer // {})[] | select(.Online == true)] | length) | tostring)
        ] | @tsv' <<< "$status_json" 2>/dev/null
    )"

    if [[ -z "$status_fields" ]]; then
        printf '1\t1\tUnknown\t0\t\t\t\t0\t0\n'
        return
    fi

    printf '1\t1\t%s\n' "$status_fields"
}

case "$action" in
    status)
        status_line
        ;;
    up)
        tailscale up --timeout=15s
        ;;
    down)
        tailscale down
        ;;
    toggle)
        if ! command -v tailscale >/dev/null 2>&1; then
            printf 'Tailscale no está instalado.\n' >&2
            exit 2
        fi

        if ! systemctl is-active --quiet tailscaled; then
            printf 'El servicio tailscaled está detenido.\n' >&2
            exit 3
        fi

        backend_state="$(
            tailscale status --json 2>/dev/null |
                jq -r '.BackendState // "Unknown"' 2>/dev/null
        )"

        if [[ "$backend_state" == "Running" ]]; then
            tailscale down
            printf 'Tailscale desconectado.\n'
        else
            tailscale up --timeout=15s
            printf 'Tailscale conectado.\n'
        fi
        ;;
    install)
        printf 'Instalando Tailscale y habilitando el control para %s...\n\n' "$(id -un)"
        sudo pacman -S --needed tailscale || exit $?
        sudo systemctl enable --now tailscaled || exit $?
        sudo tailscale set --operator="$(id -un)" || exit $?
        printf '\nInstalación lista. Conecta esta PC a tu red Tailscale.\n\n'
        tailscale up
        printf '\nPuedes cerrar esta ventana.\n'
        ;;
    repair)
        sudo systemctl enable --now tailscaled || exit $?
        sudo tailscale set --operator="$(id -un)" || exit $?
        tailscale up
        ;;
    *)
        printf 'Acción desconocida: %s\n' "$action" >&2
        exit 64
        ;;
esac
