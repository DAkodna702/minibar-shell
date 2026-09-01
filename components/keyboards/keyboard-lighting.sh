#!/usr/bin/env bash
set -euo pipefail

find_laptop_led() {
    for led_path_value in /sys/class/leds/*kbd_backlight* /sys/class/leds/*keyboard_backlight*; do
        [[ -e "$led_path_value" ]] || continue
        basename "$led_path_value"
        return 0
    done
    return 1
}

case "${1:-status}" in
    status)
        laptop_device="$(find_laptop_led || true)"
        laptop_available=false
        laptop_current=0
        laptop_max=0
        if [[ -n "$laptop_device" ]]; then
            laptop_available=true
            laptop_current="$(<"/sys/class/leds/$laptop_device/brightness")"
            laptop_max="$(<"/sys/class/leds/$laptop_device/max_brightness")"
        fi

        external_connected=false
        if lsusb -d 258a:0049 2>/dev/null | grep -q .; then
            external_connected=true
        fi

        jq -nc \
            --argjson laptopAvailable "$laptop_available" \
            --arg laptopDevice "$laptop_device" \
            --argjson laptopCurrent "$laptop_current" \
            --argjson laptopMax "$laptop_max" \
            --argjson externalConnected "$external_connected" \
            '{laptopAvailable:$laptopAvailable,laptopDevice:$laptopDevice,laptopCurrent:$laptopCurrent,laptopMax:$laptopMax,externalConnected:$externalConnected,externalUsbId:"258a:0049",externalSoftwareSupport:false}'
        ;;
    toggle-laptop)
        laptop_device="$(find_laptop_led || true)"
        [[ -n "$laptop_device" ]] || { echo "El kernel no expone la retroiluminación de la laptop" >&2; exit 3; }
        current="$(<"/sys/class/leds/$laptop_device/brightness")"
        if (( current > 0 )); then
            brightnessctl -d "$laptop_device" set 0 >/dev/null
        else
            brightnessctl -d "$laptop_device" set 100% >/dev/null
        fi
        ;;
    *)
        echo "Acción desconocida" >&2
        exit 2
        ;;
esac
