#!/bin/bash

GIT_ROOT_DIR=`git rev-parse --show-toplevel`

cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip

mkdir -p $GIT_ROOT_DIR/.bin 
mkdir -p $GIT_ROOT_DIR/.install
./aws/install --update -b $GIT_ROOT_DIR/.bin  -i $GIT_ROOT_DIR/.install

rm awscliv2.zip

