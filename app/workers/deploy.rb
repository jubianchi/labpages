require 'sidekiq/worker'
require 'web_socket/web_socket'

require_relative '../helpers/pages.rb'

class DeployWorker
  include Sidekiq::Worker
  include LabPages::Helpers::Pages

  def perform(dir, owner, repository, url = nil)
    branch = 'gl-pages'
    path = File.join(dir, owner, repository)

    if File.exist? path
      logger.info("Updating #{owner}/#{repository}...")

      if system("cd #{path}; git fetch origin; git reset --hard origin/#{branch}")
        logger.info('Successfully pulled repository!')
      else
        logger.error('Failed to pull repository!')
      end
    else
      if url != nil
        logger.info("Cloning #{url}...")

        if system("git clone #{url} #{path};cd #{path} && git checkout -f #{branch}");
          logger.info('Successfully cloned repository!')
        else
          logger.error('Failed to clone repository!')
        end
      end
    end

    client = WebSocket.new("ws://127.0.0.1:8080/status")
    client.send(
        {
            'type' => 'update',
            'content' => info(dir, owner, repository)
        }.to_json
    )
  end
end