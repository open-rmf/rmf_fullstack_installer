#!/bin/bash

env > /dev/null 2>&1

KEY_NAME=$(whiptail \
    --nocancel \
    --inputbox "Enter your AWS Key Pair name." \
    --title "Generate AWS Keys" \
    $LINES $COLUMNS rmf_fullstack_id_rsa \
    3>&1 1>&2 2>&3)

test -f $HOME/.ssh/$KEY_NAME && echo "Key already exists, aborting to prevent accidental overwrite." && exit

aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > "$KEY_NAME" 

( [ -s "$KEY_NAME" ] && chmod 0400 "$KEY_NAME" && mv "$KEY_NAME" $HOME/.ssh  ) || rm "$KEY_NAME"

test -f $HOME/.ssh/$KEY_NAME || echo "Something went wrong, Key Pair may not be available."
