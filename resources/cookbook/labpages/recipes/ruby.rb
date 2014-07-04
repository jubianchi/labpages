%w(build-essential zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libreadline-dev libncurses5-dev libffi-dev curl).each do |package|
  apt_package package
end

remote_file 'download ruby' do
  source 'http://cache.ruby-lang.org/pub/ruby/2.1/ruby-2.1.2.tar.gz'
  path "#{Chef::Config[:file_cache_path]}/ruby-2.1.2.tar.gz"
  not_if 'ruby -v | grep 2.1.2'
  notifies :run, 'execute[decompress ruby]', :immediately
end

execute 'decompress ruby' do
  command 'tar xzvf ruby-2.1.2.tar.gz'
  cwd Chef::Config[:file_cache_path]
  only_if "test -f #{Chef::Config[:file_cache_path]}/ruby-2.1.2.tar.gz"
  not_if 'ruby -v | grep 2.1.2'
  notifies :run, 'execute[build and install ruby]', :immediately
end

execute 'build and install ruby' do
  command './configure --disable-install-rdoc && make && make install'
  cwd "#{Chef::Config[:file_cache_path]}/ruby-2.1.2"
  only_if "test -d #{Chef::Config[:file_cache_path]}/ruby-2.1.2"
  not_if 'ruby -v | grep 2.1.2'
end

gem_package 'bundler'
