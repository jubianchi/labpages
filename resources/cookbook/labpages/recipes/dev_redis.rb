service 'redis-server' do
  action :stop
end

cookbook_file '/var/lib/redis/dump.rdb' do
  source 'dump.rdb'
  owner 'redis'
  group 'redis'
end

service 'redis-server' do
  action :start
end