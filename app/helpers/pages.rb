require 'open4'
require 'git'

module LabPages
  module Helpers
    module Pages
      def deploy(dir, owner, repository, url = nil)
        branch = 'gl-pages'
        path = File.join(dir, owner, repository)

        if File.exist? path
          logger.info("Updating #{owner}/#{repository}...")

          repo = Git.open(path, :log => Logger.new(STDOUT))
          repo.remote('origin').fetch
          repo.reset_hard('origin/' + branch)

          logger.info('Successfully updated repository!')
        else
          if url != nil
            logger.info("Cloning #{url}...")

            repo = Git.clone(url, repository, :path => path)
            repo.checkout('gl-pages')

            logger.info('Successfully cloned repository!')
          end
        end

        return info(dir, owner, repository)
      end

      def info(dir, owner, repository)
        path = File.join(dir, owner, repository)
        status = {
            'owner' => owner,
            'name' => repository,
            'refs' => {
                'deployed' => nil,
                'remote' => nil,
                'commits' => [],
            }
        }

        repo = Git.open(path, :log => Logger.new(STDOUT))
        repo.remote('origin').fetch

        commits = repo.log.between('HEAD', 'origin/gh-pages')
        if commits.count <= 1
          commits = [repo.gcommit('HEAD'), repo.gcommit('HEAD')]
        end

        commits.each_with_index do |commit, key|
          commit = [
              commit.sha,
              commit.message,
              commit.author.name,
              Digest::MD5.hexdigest(commit.author.email)
          ]

          if key == 0
            status['refs']['remote'] = commit
          else
            if key === (commits.count - 1)
              status['refs']['deployed'] = commit
            else
              status['refs']['commits'].push(commit)
            end
          end
        end

        status
      end
    end
  end
end
