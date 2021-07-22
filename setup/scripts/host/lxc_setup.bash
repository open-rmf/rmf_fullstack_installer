#!/bin/bash
set -a

lxc_create_storage_pool() {
  lxc storage create default dir &> /dev/null || true
}

lxc_create_network_lxdbr0() {
  lxc network create lxdbr0 &> /dev/null || true
  cat << \EOF | lxc network edit lxdbr0
config:
  ipv4.address: 10.192.240.1/24
  ipv4.nat: "true"
  ipv6.address: fd42:37f2:2cc4:2ea8::1/64
  ipv6.nat: "true"
  raw.dnsmasq: dhcp-option=6,8.8.8.8,8.8.4.4
description: ""
name: lxdbr0
type: bridge
used_by: []
managed: true
status: 
locations:
- none
EOF
}

lxc_create_profile_hostbridge() {
  lxc profile create hostbridge &> /dev/null || true
  cat << \EOF | lxc profile edit hostbridge
config: {}
description: Use the host network via bridge br0
devices:
  eth0:
    name: eth0
    nictype: bridged
    parent: br0
    type: nic
name: hostbridge
used_by: []
EOF
}

lxc_create_profile_nat() {
  lxc profile create nat &> /dev/null || true
  cat << \EOF | lxc profile edit nat 
config: {}
description: Use the lxdbr0 network
devices:
  eth0:
    name: eth0
    network: lxdbr0 
    type: nic
name: nat 
used_by: []
EOF
}


lxc_create_profile_display() {
  lxc profile create display &> /dev/null || true
  cat << \EOF | lxc profile edit display
config:
  environment.DISPLAY: :0
description: Enables graphical apps use.
devices:
  X0:
    path: /tmp/.X11-unix/X0
    source: /tmp/.X11-unix/X0
    type: disk
  mygpu:
    type: gpu
name: display
used_by: []
EOF
}

lxc_create_profile_kubernetes() {
lxc profile create kubernetes &> /dev/null || true
cat << EOF | lxc profile edit kubernetes
name: kubernetes
config:
  linux.kernel_modules: ip_tables,ip6_tables,netlink_diag,nf_nat,overlay,br_netfilter
  raw.lxc: |
    lxc.apparmor.profile=unconfined
    lxc.mount.auto=proc:rw sys:rw
    lxc.cap.drop=
    lxc.cgroup.devices.allow = a
    lxc.mount.entry = /dev/kmsg dev/kmsg none defaults,bind,create=file
  security.nesting: "true"
  security.privileged: "true"
description: Profile supporting kubernetes in containers
devices:
  aadisable:
    path: /sys/module/apparmor/parameters/enabled
    source: /dev/null
    type: disk
EOF
}

lxc_create_profile_default(){
lxc profile create default &> /dev/null || true
cat << \EOF | lxc profile edit default
config: {}
description: Default LXD profile
devices:
  root:
    path: /
    pool: default
    type: disk
name: default
EOF
}

lxc_create_profile_mounthome(){
lxc profile create mounthome &> /dev/null || true
cat << EOF | lxc profile edit mounthome 
name: mounthome 
description: Mount the home folder
devices:
  home:
    path: /root
    source: /home/$USER
    type: disk
name: mount-home
used_by: []
EOF
}

lxc_setup_all() {
  which lxc &> /dev/null || (echo "LXC not found, installing.." && apt install lxc -y)
  lxc_create_storage_pool || echo "Storage pool was not created"
  lxc_create_network_lxdbr0 || echo "Network lxcbr0 was not created"
  lxc_create_profile_display  || echo "Display profile was not created."
  lxc_create_profile_kubernetes  || echo "kubernetes profile was not created."
  lxc_create_profile_default  || echo "default profile was not created."
  lxc_create_profile_mounthome  || echo "mounthome profile was not created."
  lxc_create_profile_hostbridge  || echo "hostbridge profile was not created."
  lxc_create_profile_nat  || echo "nat profile was not created."
}

help_textbox=$(mktemp)
cat << END > $help_textbox
This will set up ( and delete any prior ) configurations on LXC:
Storage:
    default: Type dir
Networks:
    lxdbr0: Used for NAT
Profiles:
    default: Default profile
    display: Allows GUI over X11 when the host opens xhost permissions using xhost +
    kubernetes: Allows kubernetes to run with docker driver. Requires privileged LXC 
    mounthome: Mounts the home folder in the LXC container
    hostbridge: Container is a sister device on same network. Requires host to have wired connection.
    nat: Container is NATed behind a router on a separate subnet. The default network configuration.
END

whiptail --textbox $help_textbox --title "LXC Setup" $LINES $COLUMNS 

echo "Setting up LXC Configurations.."
lxc_setup_all
echo "Ensure avahi-daemon is installed"
apt install avahi-daemon -y
echo "Networks:"; lxc network list
echo "Profiles:"; lxc profile list

