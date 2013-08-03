require 'sinatra'

module LabPages
  module Controllers
    module Hook
      def self.registered(app)
        app.post '/hook/gitlab/?' do
          info = JSON.parse(request.body.read)
          branch = /([^\/]+)$/.match(info['ref'])[1]

          if branch == 'gl-pages' and info['total_commits_count'] > 0
            matches = info['commits'][0]['url'].scan(/https?:\/\/([^\/]+)\/([^\/]+)\/([^\/]+)/)[0]

            DeployWorker.perform_async(app.settings.config['repo_dir'], matches[1], matches[2], info['repository']['url'])
          end
        end
      end
    end
  end
end
