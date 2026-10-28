#!/bin/bash
# GPU stats for Waybar: short text on the bar, full details on hover

HIST=/tmp/waybar_gpu_hist

bar() { local n=$(( $1 * 20 / 100 )) s="" i; (( n > 20 )) && n=20
  for ((i=0;i<20;i++)); do if (( i<n )); then s+="█"; else s+="░"; fi; done; printf '%s' "$s"; }
spark() { local c=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █) s="" v; for v in "$@"; do (( v>100 )) && v=100; s+="${c[$(( v*7/100 ))]}"; done; printf '%s' "$s"; }

IFS=',' read -r name util temp fan pdraw plimit mused mtotal clk clkmax < <(
  nvidia-smi --query-gpu=name,utilization.gpu,temperature.gpu,fan.speed,power.draw,power.limit,memory.used,memory.total,clocks.gr,clocks.max.gr \
  --format=csv,noheader,nounits | sed 's/, /,/g')

tinfo=$(nvidia-smi -q -d TEMPERATURE)
slow=$(awk -F: '/GPU Slowdown Temp/ {gsub(/[^0-9]/,"",$2); print $2; exit}' <<< "$tinfo")
maxop=$(awk -F: '/GPU Max Operating Temp/ {gsub(/[^0-9]/,"",$2); print $2; exit}' <<< "$tinfo")
[[ -z $slow ]] && slow="?"
[[ -z $maxop ]] && maxop=90

echo "$util" >> "$HIST"; tail -n 30 "$HIST" > "$HIST.tmp" && mv "$HIST.tmp" "$HIST"

mpct=$(( mused * 100 / mtotal ))
vram=$(awk "BEGIN{printf \"%.1f / %.1f GB\", $mused/1024, $mtotal/1024}")
power=$(awk "BEGIN{printf \"%.0f / %.0f W\", $pdraw, $plimit}")
tpct=$(( temp * 100 / maxop ))

tip="$name
────────────────────────────────
Usage    $(bar "$util")  ${util}%
History  $(spark $(cat "$HIST"))  (last 60s)
Temp     $(bar "$tpct")  ${temp}°C
         slows down at ${slow}°C, max ${maxop}°C
VRAM     $(bar "$mpct")  $vram
Power    $power
Clock    $clk / $clkmax MHz
Fan      ${fan}%"

class="normal"; (( temp >= 83 )) && class="critical"
jq -cn --arg text "GPU ${util}% ${temp}°C" --arg tooltip "$tip" --arg class "$class" \
  '{text:$text, tooltip:$tooltip, class:$class}'
