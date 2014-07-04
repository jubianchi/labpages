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

['root/second', 'root/third', 'root/root-labpages', 'labpages/labpages-labpages', 'root/jekyll'].each do |repo|
  repo_owner = repo.split('/')[0]
  repo_name = repo.split('/')[1]

  git "/home/#{node['labpages']['git_user']}/repositories/#{repo_name}" do
    repository "git@labpages:#{repo}"
    reference 'gl-pages'
    user node['labpages']['git_user']
    group node['labpages']['git_user']

    action :sync
  end

  directory "#{node['labpages']['repo_dir']}/#{repo_owner}" do
    action :create
    owner node['labpages']['git_user']
    group node['labpages']['git_user']
  end

  git "#{node['labpages']['repo_dir']}/#{repo}" do
    repository "git@labpages:#{repo}"
    reference 'gl-pages'
    user node['labpages']['git_user']
    group node['labpages']['git_user']

    action :sync
  end
end

git "/home/#{node['labpages']['git_user']}/repositories/first" do
  repository "git@labpages:root/first"
  reference 'gl-pages'
  user node['labpages']['git_user']
  group node['labpages']['git_user']

  action :sync
end

git "#{node['labpages']['repo_dir']}/root/first" do
  repository "git@labpages:root/first"
  reference 'gl-pages'
  user node['labpages']['git_user']
  group node['labpages']['git_user']

  action :sync
end

execute 'revert_some_commit' do
  command 'git reset --hard origin/gl-pages~3'
  cwd "#{node['labpages']['repo_dir']}/root/first"
  user node['labpages']['git_user']
end