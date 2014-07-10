unless ::Dir.exist?(node['labpages']['app_dir'])
  git node['labpages']['app_dir'] do
    repository node['labpages']['git_repository']
    reference node['labpages']['git_revision']

    action :sync
  end
end

[node['labpages']['repo_dir'], node['labpages']['log_dir'], node['labpages']['pid_dir']].each do |dir|
  directory dir do
    owner node['labpages']['git_user']
    group node['labpages']['git_user']
    mode 0755

    action :create
  end
end

template "#{node['labpages']['config_dir']}/config.yml" do
  source 'config.yml.erb'
  owner node['labpages']['git_user']
  group node['labpages']['git_user']
  variables(node['labpages'])
end

template "#{node['labpages']['config_dir']}/sidekiq.yml" do
  source 'sidekiq.yml.erb'
  owner node['labpages']['git_user']
  group node['labpages']['git_user']
  variables(node['labpages']['sidekiq'])
end

execute 'bundle_app' do
  cwd node['labpages']['app_dir']
  command "sudo -u #{node['labpages']['git_user']} -H bundle install --deployment"
end

template "/etc/init.d/#{node['labpages']['app_name']}" do
  source 'init.d.erb'
  mode 0755
  variables(node['labpages'])
end

service 'labpages' do
  supports :start => true, :stop => true, :restart => true, :status => true
  action :nothing
end
