require 'sinatra/base'
require 'json'
require 'yaml'
require 'logger'
require 'fileutils'

class LabPagesHook < Sinatra::Base
  config = YAML.load_file('config.yml')
  logger = Logger.new(config['log_file'], 'daily')

  if  !File.exist? config['repo_dir']
    logger.info("Directory #{config['repo_dir']} does not exist, make it.")
    FileUtils.mkdir_p config['repo_dir']
  end

  set :bind, '0.0.0.0'
  set :port, 8080

  get '/ping/?' do
    'Gitlab Web Hook is up and running :-)'
  end

  post '/update/?' do
    repoInfo = JSON.parse(request.body.read)
    branch = /([^\/]+)$/.match(repoInfo['ref'])[1]
    username = repoInfo['commits'][0]['author']['name']
    repoPath = [config['repo_dir'], username, repoInfo['repository']['name']].join('/')

    logger.info("Updating #{repoInfo['repository']['name']}...")

    if branch != 'gl-pages' && branch != 'gh-pages'
      logger.info("Nothing to do with #{branch}!")
      return
    end

    if File.exist? repoPath
      logger.info("Pulling #{repoInfo['repository']['url']} into directory #{repoPath}...")

      if system("cd #{repoPath}; git pull origin; git checkout -f #{branch}")
        logger.info('Successfully pulled repository!')
      else
        logger.error('Failed to pull repository!')
      end
    else
      logger.info("Cloning #{repoInfo['repository']['url']} into directory #{repoPath}...")

      if system("git clone #{repoInfo['repository']['url']} #{repoPath};cd #{repoPath} && git checkout -f #{branch}");
        logger.info('Successfully cloned repository!')
      else
        logger.error('Failed to clone repository!')
      end
    end
  end

  # for domains
  before do
    if !request.host.end_with? config['domain']
      return
    end

    userName=request.host.gsub(config['domain'], '').gsub(/\.$/, '')

    if userName.length > 0
      match = /\/([^\/]+)/.match(request.path_info)

      if match
        repoName = match[1]
        filePath=[config['repo_dir'], userName, repoName].join('/')

        if File.exist? filePath
          if request.path_info.end_with? repoName
            redirect to(request.path_info + '/')
          end

          request.path_info = '/' + userName + '/' + request.path_info

          return
        end
      end
      filePath=[config['repo_dir'], userName, userName].join('/')

      if File.exist? filePath
        request.path_info = '/' + userName + '/' + userName + request.path_info
      end
    end
  end

  # for static files
  get %r{\.\w+$} do
    if request.path_info.include? '.git/'
      raise Sinatra::NotFound
    end

    if File.exist? config['repo_dir'] + request.path_info
      send_file config['repo_dir'] + request.path_info;
    else
      raise Sinatra::NotFound
    end
  end

  # for index.html
  get %r{.*$} do
    path = request.path_info;

    if !path.end_with? '/'
      path += '/'
    end

    match = /^\/[^\/]+\/$/.match(request.path_info)
    if match
      redirect to(config['gitlab_url'] + '/u' + request.path_info)
    end

    if File.exist?(config['repo_dir'] + path + 'index.html')
      send_file config['repo_dir'] + path + 'index.html'
    else
      if File.exist?(config['repo_dir'] + path + 'index.htm')
        send_file config['repo_dir'] + path + 'index.htm'
      else
        pass
      end
    end
  end

  not_found do
    @logo = config['logo_src']
    erb :"404"
  end

  run! if app_file == $0
end
