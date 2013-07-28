require 'sidekiq/worker'

class UpdateWorker
  include Sidekiq::Worker

  def perform(dir, owner, repository, url = nil)
    puts 'Updating'
    puts dir
    puts owner
    puts repository
    puts url
  end
end