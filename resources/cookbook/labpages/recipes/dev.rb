template "/home/#{node['labpages']['git_user']}/.ssh/id_rsa" do
  source 'dev/id_rsa'
  owner node['labpages']['git_user']
  group node['labpages']['git_user']
  mode 0600
end

template "/home/#{node['labpages']['git_user']}/.ssh/id_rsa.pub" do
  source 'dev/id_rsa.pub'
  owner node['labpages']['git_user']
  group node['labpages']['git_user']
  mode 0600
end

template "/home/#{node['labpages']['git_user']}/.ssh/config" do
  source 'dev/ssh_config'
  owner node['labpages']['git_user']
  group node['labpages']['git_user']
  mode 0700
end

npm_package "redis-commander" do
  action :install
  not_if 'which redis-commander'
end

execute 'start_redis_commander' do
  command "redis-commander -p #{node['labpages']['redis']['commander']['port']} > /dev/null 2>&1 &"

  action :run
end

include_recipe 'labpages::dev_redis'
include_recipe 'labpages::dev_gitlab'
include_recipe 'labpages::dev_fixtures'

service 'labpages' do
  action :start
end



