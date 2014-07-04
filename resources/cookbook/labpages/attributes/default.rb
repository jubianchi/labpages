default[:labpages][:app_name]                   = 'labpages'
default[:labpages][:env]                        = 'production'

default[:labpages][:git_user]                   = 'git'
default[:labpages][:git_repository]             = 'https://github.com/jubianchi/labpages.git'
default[:labpages][:git_revision]               = 'master'

default[:labpages][:app_dir]                    = "/home/#{node[:labpages][:git_user]}/#{node[:labpages][:app_name]}"
default[:labpages][:config_dir]                 = "#{node[:labpages][:app_dir]}/config"
default[:labpages][:log_dir]                    = "/var/log/#{node[:labpages][:app_name]}"
default[:labpages][:pid_dir]                    = "/var/run/#{node[:labpages][:app_name]}"

default[:labpages][:bind]                       = '0.0.0.0'
default[:labpages][:port]                       = '8181'
default[:labpages][:domain]                     = node[:labpages][:app_name]
default[:labpages][:gitlab_url]                 = "http://#{node[:labpages][:domain]}"
default[:labpages][:repo_dir]                   = "/var/#{node[:labpages][:app_name]}"
default[:labpages][:log_file]                   = "#{node[:labpages][:log_dir]}/labpages.log"
default[:labpages][:logo_src]                   = "http://placekitten.com/400/400"

default[:labpages][:sidekiq][:log_file]        = "#{node[:labpages][:log_dir]}/sidekiq.log"
default[:labpages][:sidekiq][:pid_file]        = "#{node[:labpages][:pid_dir]}/sidekiq.pid"
default[:labpages][:sidekiq][:verbose]         = true
default[:labpages][:sidekiq][:concurrency]     = 5
default[:labpages][:sidekiq][:timeout]         = 10
default[:labpages][:sidekiq][:queue]           = node[:labpages][:app_name]
