COOKBOOK_REPO=https://github.com/opscode-cookbooks
GIT=git clone --depth 1
MIRROR=

up: start provision

resurrect: down up

box: resources/wheezy/wheezy.box

box-mirror:
	make box MIRROR=http://static.jubianchi.fr/boxes/wheezy.box

box-deploy: box
	rsync -az --progress resources/wheezy/wheezy.box static.jubianchi.fr:/var/www/static.jubianchi.fr/boxes

provision:
	vagrant provision

start: down resources/wheezy/wheezy.box cookbooks Vagrantfile
	vagrant up --no-provision

cookbooks:
	mkdir -p cookbooks
	$(GIT) $(COOKBOOK_REPO)/git.git cookbooks/git
	$(GIT) $(COOKBOOK_REPO)/build-essential.git cookbooks/build-essential
	$(GIT) $(COOKBOOK_REPO)/dmg.git cookbooks/dmg
	$(GIT) $(COOKBOOK_REPO)/runit.git cookbooks/runit
	$(GIT) $(COOKBOOK_REPO)/yum.git cookbooks/yum
	$(GIT) $(COOKBOOK_REPO)/yum.git cookbooks/windows
	$(GIT) $(COOKBOOK_REPO)/apt.git cookbooks/apt
	$(GIT) https://github.com/mdxp/nodejs-cookbook.git cookbooks/nodejs
	$(GIT) https://github.com/balbeko/chef-npm.git cookbooks/npm

Vagrantfile:
	cp Vagrantfile-dist Vagrantfile

resources/wheezy/wheezy.box:
	[ ! -z "$(MIRROR)" ] && wget -O resources/wheezy/wheezy.box $(MIRROR) \
	    || [ -z "$(MIRROR)" ] && cd resources/wheezy && packer build wheezy.json

clean: down
	vagrant box remove wheezy virtualbox || true
	rm -f resources/wheezy/wheezy.box

down:
	vagrant halt -f || true
	vagrant destroy -f || true
