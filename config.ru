require 'sinatra'

require './LabPagesHook'

configure do
  set :bind,          '0.0.0.0'
  set :port,          8080
  set :app_root,      File.expand_path('../', __FILE__)
  set :sprockets,     Sprockets::Environment.new(settings.app_root)
  set :assets_prefix, '/assets'
  set :assets_path,   File.join(settings.app_root, 'assets')

  %w(. less js).each do |asset_directory|
    settings.sprockets.append_path File.join(settings.assets_path, asset_directory)
  end

  Sprockets::Helpers.configure do |config|
    config.environment = settings.sprockets
    config.prefix      = settings.assets_prefix
    config.digest      = true
    config.manifest    = Sprockets::Manifest.new(
        settings.sprockets,
        File.join(
            settings.app_root, 'assets', 'manifest.json'
        )
    )
  end
end

map Sinatra::Application.settings.assets_prefix do
  run settings.sprockets
end

map '/' do
  run LabPagesHook
end
