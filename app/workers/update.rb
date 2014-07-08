require 'sidekiq/worker'
require 'web_socket/web_socket'

require_relative '../helpers/pages.rb'
require_relative '../helpers/redis.rb'

class UpdateWorker
  include Sidekiq::Worker
  include LabPages::Helpers::Redis
  include LabPages::Helpers::Pages

  sidekiq_options :queue => 'labpages'

  def perform(dir, owner = nil, repository = nil)
    config_root = File.join(File.dirname(__FILE__), '..', '..', 'config')
    config = YAML.load_file(File.join(config_root, 'config.yml'))

    client = WebSocket.new('ws://127.0.0.1:' + config['port'].to_s + '/socket')

    if owner == nil || repository == nil
      content = dir
    else
      content = info(dir, owner, repository)
    end


    client.send(
      {
        :type => 'update',
        :content => content
      }.to_json
    )
  end
end
