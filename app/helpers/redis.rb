require 'redis'

module LabPages
  module Helpers
    module Redis
      def redis
        ::Redis.current
      end

      def fetch_users
        begin
          users = []

          JSON.parse(redis.get('labpages:repositories')).each do |repository|
            users.push(repository.split('/')[0])
          end

          users
        rescue
          []
        end
      end

      def fetch_user(name)
        begin
          repositories = []

          redis.keys('labpages:' + name + '/*').each do |key|
            repositories.push(JSON.parse(redis.get(key)))
          end

          repositories
        rescue
          nil
        end
      end

      def fetch_repositories(owner = nil)
        begin
          repositories = JSON.parse(redis.get(owner'labpages:repositories'))

          unless owner == nil
            repositories.each do |repository|
              repositories.delete(repository) unless repository.split('/')[0] == owner
            end
          end

          repositories
        rescue
          []
        end
      end

      def fetch_repository(owner, name)
        begin
          JSON.parse(self.redis.get('labpages:' + owner + '/' + name))
        rescue
          nil
        end
      end

      def fetch_all
        begin
          repositories = []

          redis.keys('labpages:*/*').each do |key|
            repositories.push(JSON.parse(redis.get(key)))
          end

          repositories
        rescue
          []
        end
      end
    end
  end
end
