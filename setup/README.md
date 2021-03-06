# setup
This document shows how to set up containers / local machine.

## Configure config.yaml
First modify [config.yaml](./config/rmf.yaml) with your specific configuration options. Each variable is documented in the yaml file.

## Run host setup
This will set up the host with various functions ( SSL, VNC etc ).

```
bash host_setup.bash
```

You should be able to access vnc at [url]/vnc. For example, https://openrobotics.demo.open-rmf.org/vnc

## Run container setup
Once the host is ready, you can setup containers. For a given `$RMF_FS_INSTANCE_NAME` as specified in your config file, two containers are created in LXC
* `$RMF_FS_INSTANCE_NAME`: Contains RMF backend
* `$RMF_FS_INSTANCE_NAME-web`: Contains rmf-web deployment with K3S

Wireguard connects all of these machines in a VPN.

You run this command to go through the setup process:

```
bash container_setup.bash config/rmf.yaml
```

You can also run a fully scripted setup. Note that this will delete any prior containers you have.

```
bash auto_setup.bash config/rmf.yaml
```
