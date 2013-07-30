#!/bin/bash

sudo apt-get update -y

sudo apt-get install -y realpath ruby1.9.3 rubygems vim build-essential zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libreadline-dev libncurses5-dev libffi-dev curl git-core openssh-server redis-server checkinstall libxml2-dev libxslt-dev libcurl4-openssl-dev libicu-dev nginx htop

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server mysql-client libmysqlclient-dev

sudo update-alternatives --set editor /usr/bin/vim.basic
