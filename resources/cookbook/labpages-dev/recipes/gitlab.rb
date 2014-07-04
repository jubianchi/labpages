apt_package 'exim4-daemon-light'

remote_file 'download gitlab' do
  source 'https://downloads-packages.s3.amazonaws.com/debian-7.5/gitlab_7.0.0-omnibus-1_amd64.deb'
  path "#{Chef::Config[:file_cache_path]}/gitlab_7.0.0-omnibus-1_amd64.deb"
  notifies :run, 'execute[install gitlab]', :immediately
end

execute 'install gitlab' do
  command 'dpkg -i gitlab_7.0.0-omnibus-1_amd64.deb'
  cwd Chef::Config[:file_cache_path]
  only_if "test -f #{Chef::Config[:file_cache_path]}/gitlab_7.0.0-omnibus-1_amd64.deb && test ! -d /opt/gitlab"
  notifies :create, 'template[configure gitlab]', :immediately
end

template 'configure gitlab' do
  source 'gitlab.rb.erb'
  path '/etc/gitlab/gitlab.rb'
  action :nothing
  notifies :run, 'execute[reconfigure gitlab]', :immediately
end

link 'gitlab vhost' do
  target_file '/etc/nginx/sites-enabled/gitlab'
  to '/var/opt/gitlab/nginx/etc/gitlab-http.conf'
  notifies :restart, 'service[nginx]', :delayed
end

service 'gitlab-nginx' do
  supports :start => true, :stop => true
  start_command 'gitlab-ctl start nginx'
  stop_command 'gitlab-ctl stop nginx'
  action :nothing
end

execute 'reconfigure gitlab' do
  command 'gitlab-ctl reconfigure'
  action :nothing
  notifies :stop, 'service[gitlab-nginx]', :immediately
  notifies :restart, 'service[nginx]', :delayed
end