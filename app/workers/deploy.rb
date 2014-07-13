require 'sidekiq/worker'

require_relative '../helpers/redis.rb'
require_relative '../helpers/pages.rb'
require_relative './update.rb'

class DeployWorker
  include Sidekiq::Worker
  include LabPages::Helpers::Redis
  include LabPages::Helpers::Pages

  sidekiq_options :queue => 'labpages'

  def perform(dir, owner, repository, url = nil, branch = nil)
    UpdateWorker.perform_async(deploy(dir, owner, repository, url, branch))
  end
end
