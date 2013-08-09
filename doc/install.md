LabPages - Install
==================

The only supported systems are currently Debian and it's derivate distros.

You will need at least **ruby 1.9.3** and **redis 2.6**.

If you want to use LabPages subdomains, you will also need **nginx**.

1. [Using Chef cookbook](#using-chef-cookbook)
2. [Manual installation](#manual-installation)

## Using Chef cookbook

Install LabPages using the Chef cookbook is as simple as including the ```labpages```recipe in your run list. You
will find everything you nedd in the [resources/cookbook](resources/cookbook) directory.
By doing this, you will deploy the default LabPages which will not configure your webserver. If you want to do so,
manually add the ```labpages::nginx```recipe to your run list.

Then you will have to configure it a bit to fit your environment:

| Attribute                                      | Description                       | Default                                                       |
| ---------------------------------------------- | --------------------------------- | ------------------------------------------------------------- |
| node['labpages']['app_name']                   | Application name                  | labpages                                                      |
| node['labpages']['env']                        | Application environment           | production                                                    |
| node['labpages']['git_user']                   | User from which to run everything | git                                                           |
| node['labpages']['git_repository']             | LabPages source repository        | https://github.com/jubianchi/labpages.git                     |
| node['labpages']['git_revision']               | Source revision                   | master                                                        |
| node['labpages']['app_dir']                    | Installation directory            | /home/#{node[labpages][git_user]}/#{node[labpages][app_name]} |
| node['labpages']['config_dir']                 | Configuration directory           | #{node[labpages][app_dir]}/config                             |
| node['labpages']['log_dir']                    | Log directory                     | /var/log/#{node[labpages][app_name]}                          |
| node['labpages']['pid_dir']                    | PID directory                     | /var/run/#{node[labpages][app_name]}                          |
| node['labpages']['bind']                       | Bound address                     | 0.0.0.0                                                       |
| node['labpages']['port']                       | Listening port                    | 8080                                                          |
| node['labpages']['domain']                     | Application domain name           | node[labpages][app_name]                                      |
| node['labpages']['gitlab_url']                 | GitLab URL                        | http://#{node[labpages][domain]}                              |
| node['labpages']['repo_dir']                   | LabPages repositories path        | /var/#{node[labpages][app_name]}                              |
| node['labpages']['log_file']                   | LabPages log file name            | #{node[labpages][log_dir]}/labpages.log                       |
| node['labpages']['logo_src']                   | 404 page logo URL                 | http://placekitten.com/400/400                                |
| node['labpages']['sidekiq']['log_file']        | Sidekiq log file name             | #{node[labpages][log_dir]}/sidekiq.log                        |
| node['labpages']['sidekiq']['pid_file']        | Sidekiq PID file name             | #{node[labpages][pid_dir]}/sidekiq.pid                        |
| node['labpages']['sidekiq']['verbose']         | Should Sidekiq be verbose         | true                                                          |
| node['labpages']['sidekiq']['concurrency']     | Sidekiq concurrency               | 5                                                             |
| node['labpages']['sidekiq']['timeout']         | Sidekiq timeout                   | 10                                                            |
| node['labpages']['sidekiq']['queue']           | Sidekiq queue name                | node[labpages][app_name]                                      |
| node['labpages']['redis']['commander']['port'] | redis-commander port              | 8081 (For development purpose only)                           |

_For an example usage of the LabPages cookoock, you can check out [the project's Vagrantfile](../Vagrantfile)._

## Manual installation

Be sure to you have everything set up before beginning the install process :

```sh
$ redis-server -v
# Redis server v=2.6.14 ...

# sudo apt-get install redis-server
```

_If you can't find ```redis-server``` 2.6 in your distro's repositories, you can use the [Dotdeb repository](http://www.dotdeb.org/instructions/)._

```
$ ruby -v
# ruby 1.9.3p194 (2012-04-20 revision 35410) ...

# sudo apt-get install ruby1.9.3
```

### Get the source code

```sh
$ cd /home/git
$ sudo -u git -H git clone https://github.com/jubianchi/labpages.git
```

### Prepare directories

```sh
$ sudo mkdir -p /var/labpages
$ sudo mkdir -p /var/log/labpages
$ sudo mkdir -p /var/run/labpages

$ sudo chown git:git /var/labpages
$ sudo chown git:git /var/log/labpages
$ sudo chown git:git /var/run/labpages
```

### Configure application

```sh
$ cd /home/git/labpages
$ sudo -u git -H cp config/config.yml-dist config/config.yml
$ sudo -u git -H vim config/config.yml

$ sudo -u git -H cp config/sidekiq.yml-dist config/sidekiq.yml
$ sudo -u git -H vim config/sidekiq.yml
```

### Install dependencies

```sh
$ sudo gem install bundler --no-ri --no-rdoc

$ cd /home/git/labpages
$ sudo -u git -H bundle install
```

### Register the services

```sh
$ sudo cp /home/git/labpages/resources/services/init.d /etc/init.d/labpages
$ sudo apdate-rc.d labpages defaults
```

### Enable nginx virtualhost

```sh
$ sudo cp /home/git/labpages/resources/vhosts/nginx.conf /etc/nginx/sites-available/labpages
$ sudo ln -s /etc/nginx/sites-available/labpages /etc/nginx/sites-enabled/labpages
```

### Start everything

```sh
$ sudo service nginx restart
$ sudo service labpages start
```
