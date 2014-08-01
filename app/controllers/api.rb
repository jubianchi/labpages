require 'json'
require 'sinatra'

require_relative '../workers.rb'

module LabPages
  module Controllers
    module API
      def self.registered(app)
        app.get '/api/ping/?' do
          content_type :json

          begin
            stats = Sidekiq::Stats.new
            stats = Sidekiq::Stats.new
            workers = Sidekiq::Workers.new

            raise if workers.size == 0
            
            {
                :message => 'LabPages Web Hook is up and running :-)',
                :up => true,
                :sidekiq => {
                    :workers => workers.size,
                    :queues => stats.queues,
                    :failed => stats.failed,
                    :processed => stats.processed - stats.failed
                }
            }
          rescue Exception => msg
            status 503
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
            status 503
            {
                :message => 'Redis server is down :\'(',
                :error => msg,
                :up => false
            }
          end.to_json
        end

        app.get '/api/repositories/?' do
          content_type :json

          fetch_all.to_json
        end

        app.get '/api/users/?' do
          content_type :json

          fetch_users.to_json
        end

        app.get '/api/users/:user/?' do |user|
          content_type :json

          fetch_user(user).to_json
        end

        app.get '/api/users/:owner/:repository/deploy/?' do |owner, repository|
          DeployWorker.perform_async(app.settings.config['repo_dir'], owner, repository, params[:url]);
        end

        app.get '/api/users/:owner/:repository/update/?' do |owner, repository|
          UpdateWorker.perform_async(app.settings.config['repo_dir'], owner, repository);
        end

        app.get '/api/users/:owner/:repository/delete/?' do |owner, repository|
          DeleteWorker.perform_async(app.settings.config['repo_dir'], owner, repository);
        end
      end
    end
  end
end
