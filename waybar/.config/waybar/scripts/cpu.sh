#!/bin/bash
# CPU stats for Waybar: short text on the bar, full details on hover

HIST=/tmp/waybar_cpu_hist
STATE=/tmp/waybar_cpu_state

bar() { local n=$(( $1 * 20 / 100 )) s="" i; (( n > 20 )) && n=20
  for ((i=0;i<20;i++)); do if (( i<n )); then s+="█"; else s+="░"; fi; done; printf '%s' "$s"; }
spark() { local c=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █) s="" v; for v in "$@"; do (( v>100 )) && v=100; s+="${c[$(( v*7/100 ))]}"; done; printf '%s' "$s"; }

# Usage since the last check
read -r _ u n s idle iow irq sirq st _ < /proc/stat
total=$((u+n+s+idle+iow+irq+sirq+st)); idleall=$((idle+iow))
usage=0
if [[ -f $STATE ]]; then
  read -r pt pi < "$STATE"; dt=$((total-pt)); di=$((idleall-pi))
  (( dt > 0 )) && usage=$(( 100 * (dt - di) / dt ))
fi
echo "$total $idleall" > "$STATE"
echo "$usage" >> "$HIST"; tail -n 30 "$HIST" > "$HIST.tmp" && mv "$HIST.tmp" "$HIST"

# Temperatures from the Intel sensor
for h in /sys/class/hwmon/hwmon*; do [[ $(cat "$h/name") == coretemp ]] && hw=$h; done
temp=$(( $(cat "$hw/temp1_input") / 1000 ))
crit=$(( $(cat "$hw/temp1_crit" 2>/dev/null || echo 100000) / 1000 ))
hot=0; for f in "$hw"/temp*_input; do t=$(( $(cat "$f") / 1000 )); (( t > hot )) && hot=$t; done

name=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ *//')
read -r avg top < <(awk '/MHz/ {s+=$4; n++; if ($4>m) m=$4} END {printf "%.0f %.0f", s/n, m}' /proc/cpuinfo)
load=$(cut -d' ' -f1-3 /proc/loadavg)
tpct=$(( temp * 100 / crit ))

tip="$name
────────────────────────────────
Usage    $(bar "$usage")  ${usage}%
History  $(spark $(cat "$HIST"))  (last 60s)
Temp     $(bar "$tpct")  ${temp}°C
         hottest core ${hot}°C, max ${crit}°C
Clock    avg $avg MHz, fastest core $top MHz
Load     $load  (1 / 5 / 15 min)"

class="normal"; (( temp >= 85 )) && class="critical"
jq -cn --arg text "CPU ${usage}% ${temp}°C" --arg tooltip "$tip" --arg class "$class" \
  '{text:$text, tooltip:$tooltip, class:$class}'
