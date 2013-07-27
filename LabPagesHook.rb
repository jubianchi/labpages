require 'json'
require 'yaml'
require 'logger'
require 'fileutils'
require 'digest/md5'
require 'open4'
require 'sinatra/base'
require 'less'
require 'sprockets-helpers'
require 'json'

class LabPagesHook < Sinatra::Base
  config = YAML.load_file('config.yml')
  logger = Logger.new(config['log_file'], 'daily')

  unless File.exist? config['repo_dir']
    logger.info("Directory #{config['repo_dir']} does not exist, make it.")
    FileUtils.mkdir_p config['repo_dir']
  end

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
          commit[4] = Digest::MD5.hexdigest(commit[4].gsub('\n', ''))
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

  helpers do
    include Sprockets::Helpers
  end

  not_found do
    @logo = config['logo_src']
    erb :"404"
  end

  get '/ping/?' do
    content_type :json

    { :message => 'LabPages Web Hook is up and running :-)' }.to_json
  end

  get '/log/?' do
    send_file config['log_file']
  end

  get '/status/?' do
    @gitlab = config['domain']
    erb :"status"
  end

  post '/update/?' do
    info = JSON.parse(request.body.read)
    branch = /([^\/]+)$/.match(info['ref'])[1]

    if branch != 'gl-pages'
      logger.info("Nothing to do with #{branch}!")
    else
      matches = repoInfo['commits'][0]['url'].scan(/https?:\/\/([^\/]+)\/([^\/]+)\/([^\/]+)/)[0]

      content_type :json
      deploy(config['repo_dir'], matches[1], matches[2], repoInfo['commits'][0]['url']).to_json
    end
  end

  get '/users/?' do
    users = []

    Dir.foreach(config['repo_dir']) do |user|
      next if user == '.' or user == '..'

      if File.directory?(File.join(config['repo_dir'], user))
        user = {
            'name' => user
        }

        users.push(user)
      end
    end

    content_type :json
    users.to_json
  end

  get '/users/:owner/repositories/?' do |owner|
    repositories = []

    Dir.foreach(File.join(config['repo_dir'], owner)) do |repository|
      next if repository == '.' or repository == '..'

      repositories.push(info(config['repo_dir'], owner, repository))
    end

    content_type :json
    repositories.to_json
  end

  get '/users/:owner/repositories/:repository/?' do |owner, repository|
    content_type :json
    info(config['repo_dir'], owner, repository).to_json
  end

  get '/users/:owner/repositories/:repository/deploy/?' do |owner, repository|
    content_type :json
    deploy(config['repo_dir'], owner, repository).to_json
  end

  get %r{\.\w+$} do
    if request.path_info.include? '.git/'
      raise Sinatra::NotFound
    end

    if File.exist? request.path_info.gsub(/^\//, '')
      send_file request.path_info.gsub(/^\//, '')
    else
      if File.exist? config['repo_dir'] + request.path_info
        send_file config['repo_dir'] + request.path_info
      else
        raise Sinatra::NotFound
      end
    end
  end

  get %r{.*$} do
    path = request.path_info

    unless path.end_with? '/'
      redirect to(path + '/')
    end

    match = /^\/[^\/]+\/$/.match(request.path_info)
    if match
      redirect to(config['gitlab_url'] + '/u' + request.path_info)
    end

    if File.exist?(config['repo_dir'] + path + 'index.htm')
      send_file config['repo_dir'] + path + 'index.htm'
    else
      if File.exist?(config['repo_dir'] + path + 'index.html')
        send_file config['repo_dir'] + path + 'index.html'
      else
        pass
      end
    end
  end
end
