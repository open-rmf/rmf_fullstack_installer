#!/bin/bash

[ $EUID -eq 0 ] || { echo "Please run script as root" && exit 1; }

vnc_export_xstartup() {
mkdir /root/.vnc
cat <<EOF > /root/.vnc/xstartup
#xsetroot -solid grey
#xterm -geometry 80x24+10+10 -ls -title "$VNCDESKTOP Desktop" &
#twm &
#gnome-session &
/usr/bin/xfce4-session &
EOF
}

vnc_setup() {
  DEBIAN_FRONTEND=noninteractive apt install ubuntu-desktop gnome-panel gnome-settings-daemon metacity xfce4 nautilus gnome-terminal -y
  DEBIAN_FRONTEND=noninteractive apt install tigervnc-standalone-server -y
}


[ $EUID -eq 0 ] || { echo "Please run script as root" && exit 1; }
echo "Setting up TigerVNC server and GUI dependencies.."; vnc_setup; vnc_export_xstartup;

whiptail --msgbox "Set up VNC Password Now." $LINES COLUMNS; vncpasswd
