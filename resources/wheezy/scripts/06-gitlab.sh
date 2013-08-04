#!/bin/bash

cd /home/git
sudo -u git -H git clone https://github.com/gitlabhq/gitlabhq.git gitlab

cd /home/git/gitlab
sudo -u git -H git checkout 5-3-stable

cd /home/git/gitlab
sudo -u git -H cp config/gitlab.yml.example config/gitlab.yml
sudo -u git -H sed -i s/localhost/$(hostname)/ config/gitlab.yml

sudo chown -R git log/
sudo chown -R git tmp/
sudo chmod -R u+rwX  log/
sudo chmod -R u+rwX  tmp/

sudo -u git -H mkdir /home/git/gitlab-satellites
sudo -u git -H mkdir tmp/pids/
sudo -u git -H mkdir tmp/sockets/
sudo chmod -R u+rwX  tmp/pids/
sudo chmod -R u+rwX  tmp/sockets/

sudo -u git -H mkdir public/uploads
sudo chmod -R u+rwX  public/uploads

sudo -u git -H cp config/puma.rb.example config/puma.rb

sudo -u git cp config/database.yml.mysql config/database.yml
sudo -u git -H sed -i 's/"secure password"//' config/database.yml
sudo -u git -H chmod o-rwx config/database.yml

cd /home/git/gitlab
sudo gem install charlock_holmes --version '0.6.9.4' --no-ri --no-rdoc

sudo -u git -H bundle install --deployment --without development test postgres unicorn aws
yes yes | sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production

