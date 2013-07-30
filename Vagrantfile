Vagrant.configure("1") do |config|
  config.vm.box_url = "wheezy.box"
  config.vm.box = "wheezy"

  config.vm.host_name = "labpages"
  config.vagrant.host = "labpages"

  config.vm.network :hostonly, "192.168.50.4"

  config.vm.provision :shell, :path => "resources/provisioning/01-packages-dependencies.sh"
  config.vm.provision :shell, :path => "resources/provisioning/02-ruby.sh"
  config.vm.provision :shell, :path => "resources/provisioning/03-system-user.sh"
  config.vm.provision :shell, :path => "resources/provisioning/04-gitlab-shell.sh"
  config.vm.provision :shell, :path => "resources/provisioning/05-database-mysql.sh"
  config.vm.provision :shell, :path => "resources/provisioning/06-gitlab.sh"
  config.vm.provision :shell, :path => "resources/provisioning/07-init-script.sh"
  config.vm.provision :shell, :path => "resources/provisioning/08-nginx.sh"
  config.vm.provision :shell, :path => "resources/provisioning/10-labpages.sh"
  config.vm.provision :shell, :path => "resources/provisioning/09-restart.sh"
end
