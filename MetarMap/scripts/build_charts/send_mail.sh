#!/bin/bash

# Mike Kuriger michael.kuriger@thryv.com
# March 21, 2024
# Notify user that their VM build is complete

# send mail to owners
mailto=mikekuriger@gmail.com
task=$1
subject="Task $task Complete"

echo "Subject: $subject" > /tmp/mail
cat /Volumes/NFS/chartmaker/build_charts/logs/$1 >> /tmp/mail
cat /tmp/mail | msmtp ${mailto} || exit 1 
