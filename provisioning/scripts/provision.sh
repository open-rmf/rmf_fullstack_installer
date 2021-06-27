#!/bin/sh

cd $1
terraform init
terraform apply
