#!/bin/bash

help_textbox=$(mktemp)
cat << END > $help_textbox
You will require the following information:
AWS Access Key ID
Secret Access Key
Region Name

You can get your access keys by following these instructions:
https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys

You can find your preferred region from this list:
https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-available-regions
END

whiptail --textbox $help_textbox --title "Configure AWS CLI" $LINES $COLUMNS 
aws configure
