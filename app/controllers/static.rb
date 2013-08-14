require 'sinatra'

require_relative '../helpers/pages.rb'

module LabPages
  module Controllers
    module Static
      include LabPages::Helpers::Pages

      def self.registered(app)
        app.not_found do
          @logo = app.settings.config['logo_src']
          erb :'404'
        end

        app.get '/status/?' do
          @gitlab = app.settings.config['gitlab_url']
          @domain = app.settings.config['domain']
          @ws_endpoint = 'ws://' + app.settings.config['domain'] + ':' + app.settings.config['port'].to_s + '/socket'
          erb :"status"
        end

        app.get %r{/pages/([^/]*)/([^/]*)/?(.*)} do |owner, repository, rest|
          if rest.include? '.git/'
            raise Sinatra::NotFound
          end

          if repository != '' and File.directory? File.join(app.settings.config['repo_dir'], owner, repository)
            unless request.path.end_with? '/'
              path = request.path

              if request.host.include? owner
                path = path.gsub(/^\/pages/, '').gsub('/' + owner + '/', '')
              end

              redirect to('/' + path + '/')
            end

            file = serve(rest, app.settings.config['repo_dir'], owner, repository)
          else
            rest = repository + ('/' + rest unless rest == nil)
            file = serve(rest, app.settings.config['repo_dir'], owner, owner + '-' + app.settings.config['domain'].gsub('.', '-'))

            unless file and File.file? file
              redirect to(app.settings.config['gitlab_url'] + '/u/' + owner) if repository == ''
            end
          end

          unless file and File.file? file
            raise Sinatra::NotFound
          end

          send_file file
        end
      end
    end
  end
end
