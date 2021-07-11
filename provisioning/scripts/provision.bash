#!/bin/bash

GIT_ROOT_DIR=`git rev-parse --show-toplevel`

cd $1

$GIT_ROOT_DIR/.bin/terraform init
$GIT_ROOT_DIR/.bin/terraform apply
