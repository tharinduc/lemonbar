#!/bin/ksh

get_date() {
  date_time=$(date "+%Y-%m-%d %H:%M:%S %Z")
  echo $date_time
}

get_battery() {
  battery_percentage=$(apm -l)
  echo "BAT: $battery_percentage%%"
}

run_lemonbar() {
  active_monitors=$(xrandr --listactivemonitors | grep + | cut -c 2)
  set -A active_monitors_arr $active_monitors
  right_str=""
  
  for monitor in "${active_monitors_arr[@]}"
  do
    right_str_format="%{S$monitor}%{r}"
    right_str="$right_str $right_str_format $(get_battery) | $(get_date)"
  done
  echo "$right_str"
}

run() {
  while true
  do
    run_lemonbar
    sleep 5
  done
}

run | lemonbar -p
