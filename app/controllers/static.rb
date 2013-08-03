require 'sinatra'

require_relative '../helpers/pages.rb'

module LabPages
  module Controllers
    module Static
      include LabPages::Helpers::Pages

      def self.registered(app)
        app.not_found do
          @logo = app.settings.config['logo_src']
          erb :"404"
        end

        app.get '/status/?' do
          @gitlab = app.settings.config['gitlab_url']
          @domain = app.settings.config['domain']
          @ws_endpoint = 'ws://' + app.settings.config['domain'] + ':' + app.settings.config['port'].to_s + '/socket'
          erb :"status"
        end

        app.get '/pages/:owner/?' do
          path = request.path_info.gsub(/^\/pages/, '')

          redirect to(app.settings.config['gitlab_url'] + '/u' + path)
        end

        app.get '/pages/:owner/:repository/*' do
          path = request.path_info.gsub(/^\/pages/, '')

          if path.include? '.git/'
            raise Sinatra::NotFound
          end

          if File.exist? path
            send_file path
          else
            if File.exist?(app.settings.config['repo_dir'] + path)
              if File.directory?(app.settings.config['repo_dir'] + path)
                if File.exist?(app.settings.config['repo_dir'] + path + 'index.htm')
                  send_file app.settings.config['repo_dir'] + path + 'index.htm'
                else
                  if File.exist?(app.settings.config['repo_dir'] + path + 'index.html')
                    send_file app.settings.config['repo_dir'] + path + 'index.html'
                  else
                    pass
                  end
                end
              else
                send_file app.settings.config['repo_dir'] + path
              end
            else
              raise Sinatra::NotFound
            end
          end
        end

        app.get '/pages/:owner/:repository/?' do |owner, repository|
          path = request.path_info

          if request.host.include? owner
            path = path.gsub(/^\/pages/, '').gsub('/' + owner + '/', '')
          end

          redirect path + '/' unless path.end_with? '/'
        end
      end
    end
  end
end
