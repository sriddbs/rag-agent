class SyncIntegrationsJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)

    SyncGmailJob.perform_later(user_id)
  end
end
