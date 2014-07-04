cookbook_file "/home/#{node['labpages']['git_user']}/.ssh/id_rsa" do
  source 'id_rsa'
  owner node['labpages']['git_user']
  group node['labpages']['git_user']
  mode 0600
end

cookbook_file "/home/#{node['labpages']['git_user']}/.ssh/id_rsa.pub" do
  source 'id_rsa.pub'
  owner node['labpages']['git_user']
  group node['labpages']['git_user']
  mode 0600
end

cookbook_file "/home/#{node['labpages']['git_user']}/.ssh/config" do
  source 'ssh_config'
  owner node['labpages']['git_user']
  group node['labpages']['git_user']
  mode 0700
end

include_recipe 'labpages-dev::gitlab'
include_recipe 'labpages-dev::redis'
include_recipe 'labpages-dev::services'





