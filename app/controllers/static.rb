require 'sinatra'
require 'sinatra-websocket'
require 'json'

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
          if request.websocket?
            request.websocket do |ws|
              ws.onopen do
                app.settings.sockets << ws
              end

              ws.onmessage do |message|
                EM.next_tick do
                    message = JSON.parse(message)

                    if message['type'] == 'update'
                      app.settings.sockets.each do |socket|
                        socket.send(message.to_json)
                      end
                    end

                    if message['type'] = 'repositories'
                      fetch_all.each do |repository|
                        ws.send(
                            {
                                'type' => 'update',
                                'content' => repository
                            }.to_json
                        )
                      end
                    end
                  end
              end

              ws.onclose do
                app.settings.sockets.delete(ws)
              end
            end
          else
            @gitlab = app.settings.config['domain']
            erb :"status"
          end
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

        app.get '/pages/:owner/:repository/?' do
          path = request.path_info.gsub(/^\/pages/, '')

          unless path.end_with? '/'
            redirect to('/pages' + path + '/')
          end
        end
      end
    end
  end
end
