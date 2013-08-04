execute 'install_redis' do
  command 'apt-get install -y redis-server'
  action :nothing
end

apt_repository "dotdeb" do
  uri "http://packages.dotdeb.org"
  distribution 'wheezy'
  components ["all"]
  key "http://www.dotdeb.org/dotdeb.gpg"

  notifies :run, resources(:execute => 'install_redis')
end





