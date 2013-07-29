require 'sidekiq/worker'
require 'web_socket/web_socket'

require_relative '../helpers/pages.rb'

class UpdateWorker
  include Sidekiq::Worker
  include LabPages::Helpers::Pages

  sidekiq_options :queue => 'labpages'

  def perform(owner, repository, url = nil)
    config_root = File.join(File.dirname(__FILE__), '..', '..', 'config')
    config = YAML.load_file(File.join(config_root, 'config.yml'))

    client = WebSocket.new('ws://127.0.0.1:' + config['port'].to_s + '/status')
    client.send(
      {
        'type' => 'update',
        'content' => info(config['repo_dir'], owner, repository)
      }.to_json
    )
  end
end
