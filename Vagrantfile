Vagrant.configure('2') do |config|
  config.vm.box = 'jubianchi/debian-wheezy-chef-amd64'

  config.vm.network :private_network, ip: '192.168.50.4'

  config.vm.hostname = 'labpages'

  config.vm.provider 'virtualbox' do |vbox|
    vbox.memory = 2048
    vbox.cpus = 2
  end

  config.cache.scope = :box
  config.cache.auto_detect = true
  config.cache.enable :gem
  config.cache.enable :apt

  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.aliases = %w(labpages.labpages root.labpages pages.labpages debian)

  config.omnibus.chef_version = :latest

  config.berkshelf.berksfile_path = 'Berksfile'
  config.berkshelf.enabled = true

  config.vm.provision 'chef_solo' do |chef|
    chef.json = {
        :nodejs => {
          :install_method => 'source',
          :version => '0.10.15'
        },
        :npm => {
            :version => '1.3.7'
        },
        :labpages => {
            :env => 'development',
            :git_user => 'vagrant',
            :app_dir => '/vagrant'
        },
        :nginx => {
            :user => 'root',
            :default_site_enabled => false
        }
    }

    chef.log_level = :debug

    chef.add_recipe 'nginx'
    chef.add_recipe 'nodejs'
    chef.add_recipe 'npm'

    chef.add_recipe 'labpages::ruby'
    chef.add_recipe 'labpages::app'
    chef.add_recipe 'labpages::nginx'
    chef.add_recipe 'labpages-dev'
  end
end
