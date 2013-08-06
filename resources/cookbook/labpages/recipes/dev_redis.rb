service 'redis-server' do
  action :stop
end

template '/var/lib/redis/dump.rdb' do
  source 'dev/dump.rdb'
  owner 'redis'
  group 'redis'
end

service 'redis-server' do
  action :start
end