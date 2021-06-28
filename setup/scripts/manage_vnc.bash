#!/bin/bash

env > /dev/null 2>&1

vnc_export_nginx() {
cat <<EOF > /etc/nginx/deploy/vnc
location /websockify {
        proxy_http_version 1.1;
        proxy_pass http://127.0.0.1:608$1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        # VNC connection timeout
        proxy_read_timeout 61s;
        # Disable cache
        proxy_buffering off;
}

location /vnc {
    index vnc.html;
    alias /usr/src/noVNC/;
    try_files \$uri \$uri/ /vnc.html;
}

EOF
systemctl restart nginx.service
}


VNC_DISPLAY=$(whiptail \
    --nocancel \
    --inputbox "Enter the Display (1-9) of the VNC server to manage." \
    --title "Manage VNC" \
    $LINES $COLUMNS 1 \
    3>&1 1>&2 2>&3)

[[ "$VNC_DISPLAY" =~ ^[0-9]$ ]] || ( echo "Integers 1-9 only." && exit )


if [[ -z `vncserver --list | grep :$VNC_DISPLAY` ]]
then
    VNC_MESSAGE="VNC server on $VNC_DISPLAY is not running."
    VNC_RUNNING=0
else
    VNC_MESSAGE="VNC server on $VNC_DISPLAY is running."
    VNC_RUNNING=1
fi

if (whiptail --title "Manage VNC" --yesno "$VNC_MESSAGE Start/Stop?" --no-button "Stop" --yes-button "Start" $LINES $COLUMNS); then
    # Start
    vnc_export_nginx $VNC_DISPLAY
    systemctl restart nginx.service
    if [ $VNC_RUNNING -eq 1 ]; then 
        echo "VNC Already Started. Doing Nothing."; 
    else 
        echo "Starting VNC on :$VNC_DISPLAY"
        vncserver --geometry 1920x1080 :$VNC_DISPLAY --passwd /root/.vnc/passwd && systemctl start novnc@$VNC_DISPLAY.service; 
    fi
else
    # Stop
    rm /etc/nginx/deploy/vnc
    systemctl restart nginx.service
    if [ $VNC_RUNNING -eq 1 ]; then 
        echo "Stopping VNC on :$VNC_DISPLAY"
        vncserver --kill :$VNC_DISPLAY; systemctl stop novnc@$VNC_DISPLAY.service
    else 
        echo "VNC wasn't running. Doing Nothing..." ; fi
fi

systemctl status novnc@$VNC_DISPLAY.service
