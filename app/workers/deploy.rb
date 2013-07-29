require 'sidekiq/worker'

require_relative '../helpers/pages.rb'
require_relative './update.rb'

class DeployWorker
  include Sidekiq::Worker
  include LabPages::Helpers::Pages

  sidekiq_options :queue => 'labpages'

  def perform(dir, owner, repository, url = nil)
    deploy(dir, owner, repository, url)

    UpdateWorker.perform_async(dir, owner, repository)
  end
end
