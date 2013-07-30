#!/bin/bash

sudo gem install sinatra --no-ri --no-rdoc

cd /home/git
sudo -u git -H git clone https://github.com/jubianchi/labpages.git

cd /home/git/labpages
sudo -u git -H cp config.yml-dist config.yml

sed -i "s?repo_dir: /data/labpages?repo_dir: /home/git/pages?" config.yml
sed -i "s?domain: labpages.dp?domain: $(hostname)?" config.yml
sed -i "s?gitlab_url: http://labpages.dp?gitlab_url: http://$(hostname)?" config.yml

sudo touch /var/log/labpages.log
sudo chown git:git /var/log/labpages.log

sudo cp resources/nginx/labpages /etc/nginx/sites-available/labpages
sudo sed -i s/labpages\\\\.dp/$(hostname)/ /etc/nginx/sites-available/labpages
sudo sed -i s/4242/12000/ /etc/nginx/sites-available/labpages
sudo ln -s /etc/nginx/sites-available/labpages /etc/nginx/sites-enabled/labpages

echo -e "\n127.0.0.1 $(hostname)" | sudo tee -a /etc/hosts

sudo cp resources/init.d/labpages /etc/init.d/labpages
sudo chmod +x /etc/init.d/labpages
sudo update-rc.d labpages defaults 21

sudo -u git -H ssh-keygen -t rsa -N "" -f /home/git/.ssh/id_rsa
