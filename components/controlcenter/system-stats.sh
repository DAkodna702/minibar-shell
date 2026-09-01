#!/usr/bin/env bash

read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
idle_before=$((idle + iowait))
total_before=$((user + nice + system + idle + iowait + irq + softirq + steal))
sleep 0.12
read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
idle_after=$((idle + iowait))
total_after=$((user + nice + system + idle + iowait + irq + softirq + steal))
delta_total=$((total_after - total_before))
delta_idle=$((idle_after - idle_before))
cpu=0
if ((delta_total > 0)); then
    cpu=$(((100 * (delta_total - delta_idle)) / delta_total))
fi

mem_total=$(awk '/MemTotal:/ {print $2}' /proc/meminfo)
mem_available=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)
ram=$(((100 * (mem_total - mem_available)) / mem_total))

amd_gpu=0
for busy_file in /sys/class/drm/card*/device/gpu_busy_percent; do
    [[ -r "$busy_file" ]] || continue
    value=$(<"$busy_file")
    ((value > amd_gpu)) && amd_gpu=$value
done

nvidia_gpu=0
if command -v nvidia-smi >/dev/null 2>&1; then
    value=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1)
    [[ "$value" =~ ^[0-9]+$ ]] && nvidia_gpu=$value
fi

gpu=$amd_gpu
((nvidia_gpu > gpu)) && gpu=$nvidia_gpu

cpu_name=$(awk -F: '/model name/ {sub(/^[ \t]+/, "", $2); print $2; exit}' /proc/cpuinfo)
gpu_name=$(lspci 2>/dev/null | awk -F': ' '/VGA compatible controller|3D controller/ {print $2}' | paste -sd ' + ' -)

printf '%s\t%s\t%s\t%s\t%s\n' "$cpu" "$gpu" "$ram" "$cpu_name" "$gpu_name"
