require 'sidekiq/worker'
require 'sidetiq'

require_relative './update.rb'

class StatusWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  sidekiq_options :queue => 'labpages'

  recurrence { hourly.minute_of_hour(0, 15, 30, 45) }

  def perform()
    config_root = File.join(File.dirname(__FILE__), '..', '..', 'config')
    config = YAML.load_file(File.join(config_root, 'config.yml'))

    Dir.foreach(config['repo_dir']) do |user|
      next if user == '.' or user == '..'

      if File.directory?(File.join(config['repo_dir'], user))
        Dir.foreach(File.join(config['repo_dir'], user)) do |repository|
          next if repository == '.' or repository == '..'

          UpdateWorker.perform_async(config['repo_dir'], user, repository)
        end
      end
    end
  end
end
