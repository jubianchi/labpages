require 'yaml'
require 'open4'
require 'git'

module LabPages
  module Helpers
    module Pages
      def store(repository)
        slug = repository[:owner] + '/' + repository[:name]
        repositories = begin
          JSON.parse(redis.get('labpages:repositories'))
        rescue
          []
        end

        repositories << slug unless repositories.include?(slug)
        redis.set('labpages:repositories', repositories.to_json)
        redis.set('labpages:' + slug, repository.to_json)

        repository
      end

      def delete(dir, owner, repository)
        slug = owner + '/' + repository
        repo_dir = File.join(dir, owner, repository)

        FileUtils.rm_rf(repo_dir)

        redis.del('labpages:' + slug)

        repositories = begin
          JSON.parse(redis.get('labpages:repositories'))
        rescue
          []
        end

        repositories.delete(slug) if repositories.include?(slug)
        redis.set('labpages:repositories', repositories.to_json)
      end

      def deploy(dir, owner, repository, url = nil, branch = nil)
        branch = 'gl-pages' if branch.nil?
        user_home = File.join(dir, owner)
        path = File.join(user_home, repository)

        strio = StringIO.new
        log = Logger.new(strio)

        if File.exist? path
          log.info("Updating #{owner}/#{repository}...")

          begin
            repo = Git.open(path, :log => log)
            repo.remote('origin').fetch
            repo.reset_hard('origin/' + branch)

            log.info('Successfully updated repository!')
          rescue Exception => exception
            log.error(exception)
          end
        else
          if url != nil
            log.info("Cloning #{url}...")

            Dir.mkdir(user_home) unless File.exist? user_home

            begin
              repo = Git.clone(url, repository, :path => user_home)
              repo.checkout(branch)

              log.info('Successfully cloned repository!')
            rescue Exception => exception
              log.error(exception)
            end
          end
        end

        config = File.join(path, '_config.yml')
        if File.exists? config
          log.info(`cd #{path} && jekyll build`)
        end

        config = File.join(path, 'conf.py')
        if File.exists? config
          log.info(`cd #{path} && sphinx-build -b html . _site`)
        end

        info(dir, owner, repository, strio)
      end

      def info(dir, owner, repository, io = nil)
        io ||= StringIO.new
        log = Logger.new(io)

        path = File.join(dir, owner, repository)
        status = {
            :owner => owner,
            :name => repository,
            :refs => {
                :deployed => nil,
                :remote => nil,
                :commits => [],
            },
            :log => nil
        }

        repo = Git.open(path, :log => Logger.new(io))

        begin
          repo.remote('origin').fetch
        rescue Exception => exception
          log.error(exception)
        end

        begin
          commits = repo.log.between('HEAD~', 'origin/' + repo.current_branch)
        rescue Exception => exception
          log.error(exception)
          commits = []
        end

        if commits.count <= 1
          commits = [repo.gcommit('HEAD'), repo.gcommit('HEAD')]
        end

        commits.each_with_index do |commit, key|
          c = [
              commit.sha,
              commit.message,
              commit.author.date,
              commit.author.email,
              Digest::MD5.hexdigest(commit.author.email)
          ]

          if key == 0
            status[:refs][:remote] = c
          else
            if key === (commits.count - 1)
              status[:refs][:deployed] = c
            else
              status[:refs][:commits].push(c)
            end
          end
        end

        status[:log] = io.string

        store(status)
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

        config = File.join(dir, owner, repository, 'conf.py')
        if File.exists? config
          path = File.join(dir, owner, repository, '_site', request)
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
