require 'sinatra'

module LabPages
  module Controllers
    module Hook
      def self.registered(app)
        app.post '/hook/gitlab/?' do
          info = JSON.parse(request.body.read)
          branch = /([^\/]+)$/.match(info['ref'])[1]

          if branch == 'gl-pages'
            matches = repoInfo['commits'][0]['url'].scan(/https?:\/\/([^\/]+)\/([^\/]+)\/([^\/]+)/)[0]

            DeployWorker.perform_async(app.settings.config['repo_dir'], matches[1], matches[2], repoInfo['commits'][0]['url']);
          end
        end
      end
    end
  end
end
