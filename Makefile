COOKBOOK_REPO=https://github.com/opscode-cookbooks
GIT=git clone --depth 1
MIRROR=

up: start provision

resurrect: down up

provision: cookbooks
	vagrant provision

start: down
	vagrant up --no-provision

bundles:
    bundle install --path vendor/bundle

down:
	vagrant halt -f || true
