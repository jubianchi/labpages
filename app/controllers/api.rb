require 'json'
require 'sinatra'

module LabPages
  module Controllers
    module API
      def self.registered(app)
        app.get '/ping/?' do
          content_type :json

          { :message => 'LabPages Web Hook is up and running :-)' }.to_json
        end

        app.get '/log/?' do
          send_file app.settings.config['log_file']
        end

        app.get '/users/?' do
          users = []

          Dir.foreach(app.settings.config['repo_dir']) do |user|
            next if user == '.' or user == '..'

            if File.directory?(File.join(app.settings.config['repo_dir'], user))
              user = {
                  'name' => user
              }

              users.push(user)
            end
          end

          content_type :json
          users.to_json
        end

        app.get '/users/:owner/repositories/?' do |owner|
          repositories = []

          Dir.foreach(File.join(app.settings.config['repo_dir'], owner)) do |repository|
            next if repository == '.' or repository == '..'

            repositories.push(info(app.settings.config['repo_dir'], owner, repository))
          end

          content_type :json
          repositories.to_json
        end

        app.get '/users/:owner/repositories/:repository/?' do |owner, repository|
          content_type :json
          info(app.settings.config['repo_dir'], owner, repository).to_json
        end

        app.get '/users/:owner/repositories/:repository/deploy/?' do |owner, repository|
          content_type :json
          deploy(app.settings.config['repo_dir'], owner, repository).to_json
        end
      end
    end
  end
end
