template "/etc/nginx/sites-available/#{node['labpages']['app_name']}" do
  source 'nginx.conf.erb'
  variables(node['labpages'])
end

link "/etc/nginx/sites-enabled/#{node['labpages']['app_name']}" do
  to "/etc/nginx/sites-available/#{node['labpages']['app_name']}"

  notifies :restart, 'service[nginx]', :delayed
end
