require 'yaml'
require 'logger'
require 'sinatra/base'
require 'sinatra/assetpack'
require 'less'

require_relative 'app/helpers/pages.rb'
require_relative 'app/helpers/redis.rb'
require_relative 'app/workers.rb'

require_relative 'app/controllers/hook.rb'
require_relative 'app/controllers/api.rb'
require_relative 'app/controllers/static.rb'
require_relative 'app/controllers/socket.rb'

module LabPages
  class Application < Sinatra::Base
    Less.paths <<  "#{settings.root}/app/assets/less"

    configure do
      set :root,          File.dirname(__FILE__)
      set :app_root,      File.join(settings.root, 'app')
      set :config_root,   File.join(settings.root, 'config')
      set :config,        YAML.load_file(File.join(settings.config_root, 'config.yml'))
      set :logger,        Logger.new(settings.config['log_file'], 'daily')
      set :bind,          settings.config['bind']
      set :port,          settings.config['port']
      set :assets_prefix, '/assets'
      set :assets_path,   File.join(settings.app_root, 'assets')
      set :views,         File.join(settings.app_root, 'views')
      set :logging,       settings.logger
      set :sockets,       []

      unless File.exist? settings.config['repo_dir']
        logger.info("Directory #{settings.config['repo_dir']} does not exist, make it.")
        FileUtils.mkdir_p settings.config['repo_dir']
      end

      register Sinatra::AssetPack

      assets {
        serve '/js',  from: 'app/assets/js'        # Default
        serve '/css', from: 'app/assets/less'      # Default

        js :appjs, '/js/app.js', [
          '/js/jquery.js',
          '/js/angular.js'
        ]

        css :appcss, '/css/app.css', [
          '/css/application.css'
        ]

        #js_compression  :jsmin    # :jsmin | :yui | :closure | :uglify
        #css_compression :simple   # :simple | :sass | :yui | :sqwish
      }

      register LabPages::Controllers::API
      register LabPages::Controllers::Hook
      register LabPages::Controllers::Static
      register LabPages::Controllers::Socket
    end

    helpers LabPages::Helpers::Redis, LabPages::Helpers::Pages
  end
end
