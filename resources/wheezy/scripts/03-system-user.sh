#!/bin/bash

sudo adduser --disabled-login --gecos 'GitLab' git --shell /bin/bash

sudo -u git -H git config --global user.name 'GitLab'
sudo -u git -H git config --global user.email 'gitlab@localhost'

