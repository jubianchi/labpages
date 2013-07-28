require 'sinatra'

module LabPages
  module Controllers
    module Hook
      def self.registered(app)
        app.get '/status/?' do
          @gitlab = app.settings.config['domain']
          erb :"status"
        end

        app.post '/update/?' do
          info = JSON.parse(request.body.read)
          branch = /([^\/]+)$/.match(info['ref'])[1]

          if branch != 'gl-pages'
            logger.info("Nothing to do with #{branch}!")
          else
            matches = repoInfo['commits'][0]['url'].scan(/https?:\/\/([^\/]+)\/([^\/]+)\/([^\/]+)/)[0]

            content_type :json
            deploy(app.settings.config['repo_dir'], matches[1], matches[2], repoInfo['commits'][0]['url']).to_json
          end
        end
      end
    end
  end
end
