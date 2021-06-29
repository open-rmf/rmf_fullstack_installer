#!/bin/bash

[ $EUID -eq 0 ] || { echo "Please run script as root" && exit 1; }

vnc_setup() {
  apt install ubuntu-desktop gnome-panel gnome-settings-daemon metacity nautilus gnome-terminal -y
  apt install tigervnc-standalone-server -y
}


[ $EUID -eq 0 ] || { echo "Please run script as root" && exit 1; }
echo "Setting up TigerVNC server and GUI dependencies.."; vnc_setup

whiptail --msgbox "Set up VNC Password Now." $LINES COLUMNS; vncpasswd
