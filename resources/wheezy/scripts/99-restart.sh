#!/bin/bash

sudo service gitlab restart 2>/dev/null || sudo service gitlab start
sudo service nginx restart

