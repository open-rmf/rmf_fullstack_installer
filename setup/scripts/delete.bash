#!/bin/bash

lxc delete $1 --force || true
lxc delete $1-web --force || true
