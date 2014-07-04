service 'gitlab-nginx' do
  supports :start => true, :stop => true, :status => true
  start_command 'gitlab-ctl start nginx'
  stop_command 'gitlab-ctl stop nginx'
  status_command 'gitlab-ctl status redis'
  action :stop
end

service 'labpages' do
  action [:enable, :start]
end

service 'nginx' do
  action :start
end