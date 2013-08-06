directory "#{node['labpages']['repo_dir']}/root" do
  action :create
  owner node['labpages']['git_user']
  group node['labpages']['git_user']
end

directory "/home/#{node['labpages']['git_user']}/repositories" do
  action :create
  owner node['labpages']['git_user']
  group node['labpages']['git_user']
end

['first', 'second'].each do |repo|
  git "/home/#{node['labpages']['git_user']}/repositories/#{repo}" do
    repository "git@labpages:root/#{repo}"
    reference 'gl-pages'
    user node['labpages']['git_user']
    group node['labpages']['git_user']

    action :sync
  end

  git "#{node['labpages']['repo_dir']}/root/#{repo}" do
    repository "git@labpages:root/#{repo}"
    reference 'gl-pages'
    user node['labpages']['git_user']
    group node['labpages']['git_user']

    action :sync
  end
end

git "/home/#{node['labpages']['git_user']}/repositories/third" do
  repository "git@labpages:root/third"
  reference 'gl-pages'
  user node['labpages']['git_user']
  group node['labpages']['git_user']

  action :sync
end

git "#{node['labpages']['repo_dir']}/root/third" do
  repository "git@labpages:root/third"
  reference 'gl-pages'
  user node['labpages']['git_user']
  group node['labpages']['git_user']

  action :sync
end

execute 'revert_some_commit' do
  command 'git reset --hard origin/gl-pages~3'
  cwd "#{node['labpages']['repo_dir']}/root/third"
  user node['labpages']['git_user']
end