#!/bin/bash

echo '{"version":1, "click_events":true}'
echo '['
echo '[],'

gen_bar() {
    time=$(date '+%a, %d %b, %H:%M')
    volume=$(pamixer --get-volume)
    battery=$(acpi -b | awk -F', ' '{print $2}')
    memory=$(free -h | awk '/Mem:/ {print $3 "/" $2}')
    mic_muted=$(pamixer --default-source --get-mute)

    if nmcli dev status | grep -E ' connected ' | grep -v 'externally' > /dev/null; then
        net_status="Online"
        net_color="#81c8be"
    else
        net_status="Offline"
        net_color="#737994"
    fi


    if [ "$mic_muted" = "true" ]; then
        mic_status=""
    else
        mic_status=""
    fi

    echo "[
        {\"full_text\": \" $time |\", \"color\": \"#e78284\", \"name\": \"time\"},
        {\"full_text\": \"$mic_status\", \"color\": \"#ef9f76\"},
        {\"full_text\": \" $volume%\", \"color\": \"#ef9f76\", \"name\": \"volume\"},
        {\"full_text\": \" $memory\", \"color\": \"#e5c890\"},
        { \"full_text\": \" $net_status\", \"color\": \"$net_color\" },
        {\"full_text\": \"󰁹 $battery\", \"color\": \"#a6d189\"}
    ],"
}

daemon_bar() {
    while true; do
        gen_bar
        sleep 5
    done
}

handle_clicks() {
    while read -r line; do
        if echo "$line" | grep -q '"name":"volume"'; then
            [[ "${line:0:1}" == "," ]] && line="${line:1}"
            button=$(echo "$line" | jq -r '.button')
            case "$button" in
                1) pavucontrol & ;;       # Clique esquerdo
                4) pamixer -i 5 ;;        # Scroll up: aumenta volume
                5) pamixer -d 5 ;;        # Scroll down: diminui volume
            esac
            gen_bar
        fi
        if echo "$line" | grep -q '"name":"time"'; then
            alacritty -e bash -c "cal -3; exec bash" &
        fi
    done
}

daemon_bar &
handle_clicks
