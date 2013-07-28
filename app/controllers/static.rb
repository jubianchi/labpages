require 'sinatra'

module LabPages
  module Controllers
    module Static
      def self.registered(app)
        app.not_found do
          @logo = app.settings.config['logo_src']
          erb :"404"
        end

        app.get %r{\.\w+$} do
          if request.path_info.include? '.git/'
            raise Sinatra::NotFound
          end

          if File.exist? request.path_info.gsub(/^\//, '')
            send_file request.path_info.gsub(/^\//, '')
          else
            if File.exist? app.settings.config['repo_dir'] + request.path_info
              send_file app.settings.config['repo_dir'] + request.path_info
            else
              raise Sinatra::NotFound
            end
          end
        end

        app.get %r{.*$} do
          path = request.path_info

          unless path.end_with? '/'
            redirect to(path + '/')
          end

          match = /^\/[^\/]+\/$/.match(request.path_info)
          if match
            redirect to(app.settings.config['gitlab_url'] + '/u' + request.path_info)
          end

          if File.exist?(app.settings.config['repo_dir'] + path + 'index.htm')
            send_file app.settings.config['repo_dir'] + path + 'index.htm'
          else
            if File.exist?(app.settings.config['repo_dir'] + path + 'index.html')
              send_file app.settings.config['repo_dir'] + path + 'index.html'
            else
              pass
            end
          end
        end
      end
    end
  end
end
