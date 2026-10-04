#!/bin/sh

# Network interfaces.
WIFI_IF="${WIFI_IF:-iwx0}"
ETH_IF="${ETH_IF:-re1}"

# Filesystem to monitor.
DISK_FS="${DISK_FS:-/home}"

# cwm groups.
GROUPS="1 2 3 4 5 6 7 8 9"

# Desktop theme colors.
BG="#111313"          # near-black charcoal background
FG="#c8c8b8"          # pale warm gray text
MUTED="#777b70"       # muted gray-green text
ACCENT="#9a9b68"      # olive green accent
ACTIVE_BG="#555943"   # dark olive active-group background
BLUE="#667783"        # muted blue-gray
YELLOW="#c9bd82"      # warm yellow-beige


current_group()
{
	current=$(
		xprop -root _NET_CURRENT_DESKTOP 2>/dev/null |
			awk -F '=' '{ gsub(/[ ,]/, "", $2); print $2 }'
		)

		case "$current" in
			''|*[!0-9]*)
				echo 1
				;;
			0)
				echo 1
				;;
			*)
				echo "$current"
				;;
		esac
}


groups()
{
	current=$(current_group)
	output=""

	for group in $GROUPS; do
		if [ "$group" = "$current" ]; then
			output="${output}%{B${ACTIVE_BG}}%{F${FG}}  $group  %{F-}%{B-}"
		else
			output="${output}%{F${MUTED}}  $group  %{F-}"
		fi
	done

	printf '%s' "$output"
}

battery()
{
	percentage=$(apm -l 2>/dev/null)
	ac=$(apm -a 2>/dev/null)
	status=$(apm -b 2>/dev/null)

	if [ -z "$percentage" ]; then
		printf 'BAT --'
		return
	fi

	case "$status" in
		3)
			state="charging"
			;;
		*)
			if [ "$ac" = "1" ]; then
				state="AC"
			else
				state="battery"
			fi
			;;
	esac

	printf 'BAT %s%% %s' "$percentage" "$state"
}

volume()
{
	level=$(sndioctl -n output.level 2>/dev/null)
	mute=$(sndioctl -n output.mute 2>/dev/null)

	if [ "$mute" = "1" ]; then
		printf 'VOL muted'
	elif [ -n "$level" ]; then
		awk -v level="$level" '
		BEGIN {
			printf "VOL %d%%", level * 100 + 0.5
}
'
else
	printf 'VOL --'
	fi
}


interface_status()
{
	iface=$1

	if ! ifconfig "$iface" >/dev/null 2>&1; then
		printf 'down'
		return
	fi

	status=$(
		ifconfig "$iface" 2>/dev/null |
			awk '/status:/ { print $2; exit }'
		)

		if [ "$status" = "active" ]; then
			printf 'up'
		else
			printf 'down'
		fi
}


wifi_status()
{
	if ! ifconfig "$WIFI_IF" >/dev/null 2>&1; then
		printf 'WIFI down'
		return
	fi

	status=$(
		ifconfig "$WIFI_IF" 2>/dev/null |
			awk '/status:/ { print $2; exit }'
		)

		nwid=$(
			ifconfig "$WIFI_IF" 2>/dev/null |
				awk '$1 == "nwid" { print $2; exit }'
			)

			if [ "$status" = "active" ]; then
				if [ -n "$nwid" ]; then
					printf 'WIFI %s' "$nwid"
				else
					printf 'WIFI up'
				fi
			else
				printf 'WIFI down'
			fi
}


ethernet_status()
{
	status=$(interface_status "$ETH_IF")

	if [ "$status" = "up" ]; then
		printf 'ETH up'
	else
		printf 'ETH down'
	fi
}


temperature()
{
	# acpithinkpad0 is used as the general ThinkPad temperature.
	# nvme0 is more appropriate for monitoring SSD temperature.
	temp=$(
		sysctl hw.sensors.acpithinkpad0 2>/dev/null |
			awk -F= '
		/temp[0-9]+=.*degC/ {
			gsub(/ degC.*/, "", $2)
			print $2
			exit
}
'
)

if [ -n "$temp" ]; then
	printf 'TEMP %sC' "$temp"
else
	printf 'TEMP --'
fi
}


ram()
{
	page_size=$(sysctl -n hw.pagesize 2>/dev/null)
	[ -n "$page_size" ] || page_size=4096

	total=$(sysctl -n hw.physmem 2>/dev/null)

	free_pages=$(
		vmstat -s 2>/dev/null |
			awk '/pages free/ { print $1; exit }'
		)

		if [ -n "$total" ] && [ -n "$free_pages" ]; then
			free=$((free_pages * page_size))
			available=$((total - free))

			awk -v used="$available" -v total="$total" '
			BEGIN {
				printf "RAM %.1f/%.1fG",
				used / 1073741824,
				total / 1073741824
}
'
else
	printf 'RAM --'
		fi
}


disk()
{
	df -h "$DISK_FS" 2>/dev/null |
		awk 'NR == 2 {
			printf "DISK %s free", $4
		}'
}


right_status()
{
	# lemonbar displays this from left to right.
	# Therefore volume is the rightmost item.
	printf '%s  %s  %s  %s  %s  %s  %s %s' \
		"%{F${MUTED}}$(disk)%{F-}" \
		"%{F${BLUE}}$(ram)%{F-}" \
		"%{F${YELLOW}}$(temperature)%{F-}" \
		"%{F${ACCENT}}$(ethernet_status)%{F-}" \
		"%{F${ACCENT}}$(wifi_status)%{F-}" \
		"%{F${FG}}$(battery)%{F-}" \
		"%{F${FG}}$(date '+%a %d %b %H:%M')%{F-}" \
		"%{F${YELLOW}}$(volume) %{F-}"
}


run() {
	while :; do
		printf '%%{l}%s%%{r}%s\n' \
			"$(groups)" \
			"$(right_status)"

		sleep 2
	done
}

run | lemonbar -p -g 1920x24+0+0 -B "#111313" -F "#c8c8b8"
