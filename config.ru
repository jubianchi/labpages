require 'sidekiq/web'
require 'sidetiq'
require 'sidetiq/web'

require ::File.expand_path('application.rb',  __dir__)

map '/' do
  run LabPages::Application
end

map '/sidekiq' do
  run Sidekiq::Web
end