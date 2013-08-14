apt_package "expect" do
  action :install
end

directory '/home/git/gitlab/tmp/backups' do
  owner 'git'
  group 'git'

  action :create
end

cookbook_file '/home/git/gitlab/tmp/backups/1375649073_gitlab_backup.tar' do
  source '1375649073_gitlab_backup.tar'
  owner 'git'
  group 'git'
end

cookbook_file '/tmp/restore.expect' do
  source 'restore.expect'
  owner node['labpages']['git_user']
  group node['labpages']['git_user']
end

service 'gitlab' do
  action :stop
end

execute 'restore_gitlab_backup' do
  command "cd /home/git/gitlab && sudo -u git -H RAILS_ENV=production expect -f /tmp/restore.expect && rm -f /tmp/expect"

  action :run
end

service 'gitlab' do
  action :start
end
