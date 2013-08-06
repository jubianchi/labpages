#!/bin/bash

sudo /etc/init.d/hostname.sh start

sudo -u git -H sed -i s/debian/$(hostname)/ /home/git/gitlab/config/gitlab.yml
sudo -u git -H sed -i "s/debian/$(hostname)/" /home/git/gitlab-shell/config.yml

echo "Default login for gitlab: root"
echo "Default password for gitlab: labpages"
