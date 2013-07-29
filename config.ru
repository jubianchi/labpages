require 'sidekiq/web'
require 'sidetiq/web'

require ::File.expand_path('../application.rb',  __FILE__)

map LabPages::Application.settings.assets_prefix do
  run LabPages::Application.settings.sprockets
end

map '/' do
  run LabPages::Application
end

map '/sidekiq' do
  run Sidekiq::Web
end