#!/bin/bash

sudo adduser --disabled-login --gecos 'GitLab' git

sudo -u git -H git config --global user.name 'GitLab'
sudo -u git -H git config --global user.email 'gitlab@localhost'

