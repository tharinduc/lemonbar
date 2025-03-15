#!/bin/ksh

get_date() {
  date_time=$(date "+%Y-%m-%d %H:%M:%S %Z")
  echo $date_time
}

get_battery() {
  battery_percentage=$(apm -l)
  echo "BAT: $battery_percentage%%"
}

get_network() {
  is_wifi=$(ifconfig iwx0 | grep -o 'status: active' | wc -l)
  is_ethernet=$(ifconfig re1 | grep -o 'status: active' | wc -l)
  net_str=""
  if [[ $is_wifi -eq 1 ]]; then
    wifi_strength=$(ifconfig iwx0 | grep -oE '[[:digit:]]{1,2}%')
    net_str="WiFi: $wifi_strength"
  elif [[ $is_ethernet -eq 1 ]]; then
    net_str="NET: ethernet"
  else
    net_str="NET: no internet"
  fi
  echo "$net_str"
}

get_volume() {
  is_muted=$(sndioctl | grep 'output.mute' | grep -oE '[[:digit:]]')
  volume=$(sndioctl | grep 'output.level' | grep -oE '[[:digit:]]\.[[:digit:]]{3}')
  volume_percentage=$(echo $volume | awk '{ printf "%d", int(($1*100)+0.5) }')
  volume_str=""

  if [[ $is_muted -eq 1 ]]; then
    volume_str="Vol: muted"
  else
    volume_str="Vol: $volume_percentage%"
  fi
  echo "$volume_str"
}

build_lemonbar() {
  active_monitors=$(xrandr --listactivemonitors | grep + | cut -c 2)
  set -A active_monitors_arr $active_monitors
  right_str=""
  
  for monitor in "${active_monitors_arr[@]}"
  do
    right_str_format="%{S$monitor}%{r}"
    right_str="$right_str $right_str_format $(get_volume) | $(get_network) | $(get_battery) | $(get_date)"
  done
  echo "$right_str"
}

run() {
  while true
  do
    build_lemonbar
    sleep 5
  done
}

run | lemonbar -p
