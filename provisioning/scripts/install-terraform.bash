#!/bin/bash

GIT_ROOT_DIR=`git rev-parse --show-toplevel`

cd /tmp
which unzip || sudo apt install curl unzip -y
curl "https://releases.hashicorp.com/terraform/1.0.1/terraform_1.0.1_linux_amd64.zip" -o "terraform.zip"
unzip terraform.zip

mkdir -p $GIT_ROOT_DIR/.bin
mv ./terraform $GIT_ROOT_DIR/.bin
rm terraform.zip

