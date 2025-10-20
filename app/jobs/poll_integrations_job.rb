class PollIntegrationsJob < ApplicationJob
  queue_as :default

  def perform
    User.find_each do |user|
      next unless user.google_access_token.present?

      PollGmailJob.perform_later(user.id)
      PollCalendarJob.perform_later(user.id)
      PollHubspotJob.perform_later(user.id) if user.hubspot_access_token.present?
    end
  end
end
