#!/bin/bash

cd /home/git

sudo -u git -H git clone https://github.com/gitlabhq/gitlab-shell.git

cd gitlab-shell
sudo -u git -H git checkout v1.4.0

sudo -u git -H cp config.yml.example config.yml
sudo sed -i "s/localhost/$(hostname)/" config.yml

sudo -u git -H ./bin/install
