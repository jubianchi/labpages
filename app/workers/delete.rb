require 'sidekiq/worker'
require 'faye/websocket'
require 'eventmachine'

require_relative '../helpers/pages.rb'
require_relative '../helpers/redis.rb'

class DeleteWorker
  include Sidekiq::Worker
  include LabPages::Helpers::Redis
  include LabPages::Helpers::Pages

  sidekiq_options :queue => 'labpages'

  def perform(dir, owner, repository)
    delete(dir, owner, repository)

    config_root = File.join(File.dirname(__FILE__), '..', '..', 'config')
    config = YAML.load_file(File.join(config_root, 'config.yml'))

    EM.run {
      client = Faye::WebSocket::Client.new('ws://127.0.0.1:' + config['port'].to_s + '/socket')

      client.send(
        {
          :type => 'delete',
          :content => {
              :owner => owner,
              :name => repository
          }
        }.to_json
      )

      client.close
    }
  end
end
