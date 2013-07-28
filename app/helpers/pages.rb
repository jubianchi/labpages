require 'open4'

module LabPages
  module Helpers
    module Pages
      def deploy(dir, owner, repository, url = nil)
        branch = 'gl-pages'
        path = File.join(dir, owner, repository)

        if File.exist? path
          logger.info("Updating #{owner}/#{repository}...")

          if system("cd #{path}; git reset --hard; git pull origin; git checkout -f #{branch}")
            logger.info('Successfully pulled repository!')
          else
            logger.error('Failed to pull repository!')
          end
        else
          if url != nil
            logger.info("Cloning #{url}...")

            if system("git clone #{url} #{path};cd #{path} && git checkout -f #{branch}");
              logger.info('Successfully cloned repository!')
            else
              logger.error('Failed to clone repository!')
            end
          end
        end

        return info(dir, owner, repository)
      end

      def info(dir, owner, repository)
        path = File.join(dir, owner, repository)
        pid, stdin, stdout, stderr = Open4.popen4("cd #{path} && git fetch origin")
        ignored, exitcode = Process::waitpid2 pid
        status = {
            'owner' => owner,
            'name' => repository,
            'refs' => {
                'deployed' => nil,
                'remote' => nil,
                'commits' => [],
            },
            'output' => stdout.read(),
            'error' => stderr.read()
        }

        if exitcode.to_i == 0
          args = '--pretty=format:\'%H||%s||%cr||%an||%ae\' --date=relative'
          commits = `cd #{path} && git --no-pager log HEAD^...origin/gl-pages #{args}`.lines()

          if commits.length <= 1
            commits = `cd #{path} && git --no-pager log HEAD #{args}`.lines()
            commits = [commits[0], commits[0]]
          end

          commits.each_with_index do |commit, key|
            commit = commit.split('||')

            if commit[4]
              commit[4] = commit[4].downcase.lstrip.rstrip
              commit[4] = Digest::MD5.hexdigest(commit[4])
            end

            if key == 0
              status['refs']['remote'] = commit
            else
              if key === (commits.length - 1)
                status['refs']['deployed'] = commit
              else
                status['refs']['commits'].push(commit)
              end
            end
          end
        end

        return status
      end
    end
  end
end
