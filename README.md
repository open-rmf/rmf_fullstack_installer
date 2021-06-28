# rmf_fullstack_installer
This repository provides tooling to:
* Automatically sets up a minimal full deployment example of RMF with rmf-web ( including SSL certificate generation )
* Allows for easier collaborative support for debugging using noVNC
* A successful run provides assurance of deployment fitness since the build and smoke tests passed

## TLDR
```
# Provision Cloud Machine 
bash provisioning/provision-cloud-machine.bash

# Set Up Cloud Machine
bash setup/host-setup.bash

# Provision and Deploy
bash setup/container-setup.bash setup/config/rmf.yaml
```

## Infrastructure Requirements

You can run this setup on your local machine, or provision a machine in the cloud. For consistency, we test our system on Amazon Web Services AMI `ami-0d058fe428540cd89` with these specs:
* Ubuntu 20.04 LTS AMI (x86) 
* c5.2xlarge  (15GB RAM, 4vCPU, 10 Gbps)
* 64GB storage

The `host-setup` step is quick and only needs to be done once per cloud instance. 

The `container-setup` step takes about 45 minutes on these specs, but can go faster with more powerful machines. Subsequent builds will be faster, unless you delete the container to start "fresh".

