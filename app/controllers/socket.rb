require 'sinatra'
require 'sinatra-websocket'
require 'json'
require 'eventmachine'

require_relative '../helpers/pages.rb'

module LabPages
  module Controllers
    module Socket
      def self.registered(app)
        app.get '/socket/?' do
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

                  if message['type'] == 'delete'
                    app.settings.sockets.each do |socket|
                      socket.send(message.to_json)
                    end
                  end

                  if message['type'] == 'repositories'
                    fetch_all.each do |repository|
                      ws.send(
                          {
                              :type => 'repository',
                              :content => repository
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
          end
        end
      end
    end
  end
end
