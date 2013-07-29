require 'sidekiq/worker'
require 'sidetiq'
require 'web_socket/web_socket'

require_relative '../helpers/pages.rb'

class StatusWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable
  include LabPages::Helpers::Pages

  sidekiq_options :queue => 'labpages'

  recurrence { minutely() }

  def perform()
    config_root = File.join(File.dirname(__FILE__), '..', '..', 'config')
    config = YAML.load_file(File.join(config_root, 'config.yml'))
    client = WebSocket.new('ws://127.0.0.1:' + config['port'].to_s + '/status')

    Dir.foreach(config['repo_dir']) do |user|
      next if user == '.' or user == '..'

      if File.directory?(File.join(config['repo_dir'], user))
        Dir.foreach(File.join(config['repo_dir'], user)) do |repository|
          next if repository == '.' or repository == '..'

          client.send(
              {
                  'type' => 'update',
                  'content' => info(config['repo_dir'], user, repository)
              }.to_json
          )
        end
      end
    end
  end
end
