#!/bin/bash

parse_yaml_and_export(){
  export ${1::-1}=$2
}

get_repos_file(){
  regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
  rm /tmp/$2.repos > /dev/null 2>&1 || true
  if [[ $1 =~ $regex ]]; then wget $1 -O /tmp/$2.repos; else cp $1 /tmp/$2.repos; fi
}

export_config_vars() {
    while read envname; do [[ $envname == \#* ]] || parse_yaml_and_export $envname; done < $1
}

create_container() {
  echo "Creating container $1.."
  lxc launch ubuntu:20.04 $1
  lxc profile assign $1 default,nat
  lxc restart $1 || lxc start $1
}

eval_retry () {
while ! eval $1;
do
  echo "Retrying Command.."
  sleep 2
done
}

get_ingress_ip() { 
    while true; do
    	ip=`kubectl get service --namespace ingress-nginx ingress-nginx-controller  --output jsonpath='{.status.loadBalancer.ingress[0].ip}'`
    if [[ $ip = 172* ]]; then continue; fi
	if [[ ! -z $ip ]]; then echo $ip && break; fi
 	sleep 2
    done
}

get_lxc_ip() {
    while true; do
    	ip=`lxc exec $1 -- ip -4 addr show $2 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'`
        if [[ $ip = 172* ]]; then continue; fi
        if [[ ! -z $ip ]]; then echo $ip && break; fi
	sleep 2
    done
}

install_docker() {
    apt-get install \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release -y

    # Install Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    echo \
      "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install docker-ce docker-ce-cli containerd.io -y
}

restart_wg(){
    wg-quick down wg0 > /dev/null 2>&1 || true
    systemctl restart wg-quick@wg0.service
    systemctl enable wg-quick@wg0.service
}

generate_wg0_client_conf() {
# $1 - privatekey
# $2 - subnet
# $3 - device id
# $4 - publickey
# $5 - server external ip
# $6 - conf file path
cat << END > $6
[Interface]
PrivateKey = $1 
Address = $2.$3/32
DNS = 8.8.8.8
PostUp = ping $2.1 -c 1

[Peer]
PublicKey = $4 
Endpoint = $5:51820
AllowedIPs = $2.0/24
END
}
