require 'yaml'
require 'open4'
require 'git'
require 'redis'

module LabPages
  module Helpers
    module Pages
      def redis
        Redis.new
      end

      def store(repository)
        slug = repository[:owner] + '/' + repository[:name]
        repositories = begin
          JSON.parse(@redis.get('labpages:repositories'))
        rescue
          []
        end

        repositories << slug unless repositories.include?(slug)
        self.redis.set('labpages:repositories', repositories.to_json)
        self.redis.set('labpages:' + slug, repository.to_json)
      end

      def fetch(owner, repository)
        begin
          JSON.parse(self.redis.get('labpages:' + owner + '/' + repository))
        rescue
          {}
        end
      end

      def fetch_all()
        repositories = []
        slugs = begin
          JSON.parse(self.redis.get('labpages:repositories'))
        rescue
          []
        end

        slugs.each do |slug|
          repositories << JSON.parse(self.redis.get('labpages:' + slug))
        end

        repositories
      end

      def deploy(dir, owner, repository, url = nil)
        branch = 'gl-pages'
        user_home = File.join(dir, owner)
        path = File.join(user_home, repository)

        if File.exist? path
          logger.info("Updating #{owner}/#{repository}...")

          repo = Git.open(path, :log => Logger.new(STDOUT))
          repo.remote('origin').fetch
          repo.reset_hard('origin/' + branch)

          logger.info('Successfully updated repository!')
        else
          if url != nil
            logger.info("Cloning #{url}...")

            Dir.mkdir(user_home) unless File.exist? user_home
            repo = Git.clone(url, repository, :path => user_home)
            repo.checkout('gl-pages')

            logger.info('Successfully cloned repository!')
          end
        end

        config = File.join(path, '_config.yml')
        puts config
        if File.exists? config
          `cd #{path} && jekyll build`
        end
      end

      def info(dir, owner, repository)
        path = File.join(dir, owner, repository)
        status = {
            :owner => owner,
            :name => repository,
            :refs => {
                :deployed => nil,
                :remote => nil,
                :commits => [],
            }
        }

        repo = Git.open(path, :log => Logger.new(STDOUT))

        begin
          repo.remote('origin').fetch
        rescue Exception => exception
          puts exception
        end

        begin
          commits = repo.log.between('HEAD~', 'origin/gl-pages')
        rescue
          commits = 0
        end

        if commits.count <= 1
          commits = [repo.gcommit('HEAD'), repo.gcommit('HEAD')]
        end

        commits.each_with_index do |commit, key|
          commit = [
              commit.sha,
              commit.message.force_encoding('UTF-8'),
              commit.author.date,
              commit.author.name,
              Digest::MD5.hexdigest(commit.author.email)
          ]

          if key == 0
            status[:refs][:remote] = commit
          else
            if key === (commits.count - 1)
              status[:refs][:deployed] = commit
            else
              status[:refs][:commits].push(commit)
            end
          end
        end

        store(status)

        status
      end

      def serve(request, dir, owner, repository)
        path = File.join(dir, owner, repository, request)

        config = File.join(dir, owner, repository, '_config.yml')
        if File.exists? config
          config = YAML.load_file(config)

          path = File.join(dir, owner, repository, '_site', request)
          if config['destination']
            path = File.join(dir, owner, repository, config['destination'], request)
          end
        end

        if File.directory?(path)
          if File.exist?(File.join(path, 'index.htm'))
            path = File.join(path, 'index.htm')
          end

          if File.exist?(File.join(path, 'index.html'))
            path = File.join(path, 'index.html')
          end
        end

        path
      end
    end
  end
end
