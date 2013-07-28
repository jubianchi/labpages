require 'yaml'
require 'logger'
require 'sprockets-helpers'
require 'sinatra/base'

require_relative 'app/helpers/pages.rb'
require_relative 'app/controllers/hook.rb'
require_relative 'app/controllers/api.rb'
require_relative 'app/controllers/static.rb'

module LabPages
  class Application < Sinatra::Base
    configure do
      set :app_root,      File.join(settings.root, 'app')
      set :config_root,   File.join(settings.root, 'config')
      set :config,        YAML.load_file(File.join(settings.config_root, 'config.yml'))
      set :logger,        Logger.new(settings.config['log_file'], 'daily')
      set :bind,          '0.0.0.0'
      set :port,          8080
      set :sprockets,     Sprockets::Environment.new(settings.app_root)
      set :assets_prefix, '/assets'
      set :assets_path,   File.join(settings.app_root, 'assets')
      set :views,         File.join(settings.app_root, 'views')
      set :logging,       settings.logger

      unless File.exist? settings.config['repo_dir']
        logger.info("Directory #{settings.config['repo_dir']} does not exist, make it.")
        FileUtils.mkdir_p settings.config['repo_dir']
      end

      %w(. less js).each do |asset_directory|
        settings.sprockets.append_path File.join(settings.assets_path, asset_directory)
      end

      Sprockets::Helpers.configure do |config|
        config.environment = settings.sprockets
        config.prefix      = settings.assets_prefix
        config.digest      = true
        config.manifest    = Sprockets::Manifest.new(
            settings.sprockets,
            File.join(
                settings.app_root, 'assets', 'manifest.json'
            )
        )
      end

      register LabPages::Controllers::API
      register LabPages::Controllers::Hook
      register LabPages::Controllers::Static
    end

    helpers do
      include Sprockets::Helpers
      include LabPages::Helpers::Pages
    end
  end
end
