require 'json'
require 'sinatra'

require_relative '../workers/deploy.rb'

module LabPages
  module Controllers
    module API
      def self.registered(app)
        app.get '/api/ping/?' do
          content_type :json

          begin
            stats = Sidekiq::Stats.new

            {
                :message => 'LabPages Web Hook is up and running :-)',
                :up => true,
                :sidekiq => {
                    :failed => stats.failed,
                    :processed => stats.processed - stats.failed
                }
            }
          rescue Exception => msg
            {
                :message => 'LabPages Web Hook is down :\'(',
                :error => msg,
                :up => false
            }
          end.to_json
        end

        app.get '/api/ping/redis/?' do
          content_type :json

          begin
            Redis.new.ping

            {
                :message => 'Redis server is up and running :-)',
                :up => true
            }
          rescue Exception => msg
            {
                :message => 'Redis server is down :\'(',
                :error => msg,
                :up => false
            }
          end.to_json
        end

        app.get '/api/users/?' do
          content_type :json

          users = []

          Dir.foreach(app.settings.config['repo_dir']) do |user|
            next if user == '.' or user == '..'

            if File.directory?(File.join(app.settings.config['repo_dir'], user))
              user = {
                  :name => user
              }

              users.push(user)
            end
          end

          users.to_json
        end

        app.get '/api/users/:owner/repositories/?' do |owner|
          content_type :json

          repositories = []

          Dir.foreach(File.join(app.settings.config['repo_dir'], owner)) do |repository|
            next if repository == '.' or repository == '..'

            repositories.push(info(app.settings.config['repo_dir'], owner, repository))
          end

          repositories.to_json
        end

        app.get '/api/users/:owner/repositories/:repository/?' do |owner, repository|
          content_type :json

          info(app.settings.config['repo_dir'], owner, repository).to_json
        end

        app.get '/api/users/:owner/repositories/:repository/deploy/?' do |owner, repository|
          DeployWorker.perform_async(app.settings.config['repo_dir'], owner, repository);
        end
      end
    end
  end
end
