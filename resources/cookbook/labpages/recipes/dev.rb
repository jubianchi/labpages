npm_package "redis-commander" do
  action :install
  not_if 'which redis-commander'
end

execute 'start_redis_commander' do
  command "redis-commander -p #{node['labpages']['redis']['commander']['port']} > /dev/null 2>&1 &"

  action :run
end