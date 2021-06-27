#!/bin/sh
if [[ $EUID -ne 0 ]]; then
   echo -e "This script must be run as root"
   exit 1
fi

cd /tmp
curl "https://releases.hashicorp.com/terraform/1.0.1/terraform_1.0.1_linux_amd64.zip" -o "terraform.zip"
unzip terraform.zip
mv ./terraform /usr/local/bin
rm terraform.zip

which terraform || echo "Something went wrong installing Terraform."

