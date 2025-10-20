class PollHubspotJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    return unless user.hubspot_token.present?

    client = user.hubspot_client

    # Get timestamp for last check (Hubspot uses milliseconds)
    last_check = user.last_hubspot_check_at || 5.minutes.ago
    last_check_ms = (last_check.to_f * 1000).to_i

    begin
      # Search for recently modified contacts
      response = client.search_recently_modified_contacts(last_check_ms)

      contacts = response['results'] || []

      return if contacts.empty?

      Rails.logger.info "Found #{contacts.count} Hubspot changes for user #{user.id}"

      contacts.each do |contact|
        process_hubspot_contact(user, contact)
      end

      # Update last check timestamp
      user.update!(last_hubspot_check_at: Time.now)

    rescue => e
      Rails.logger.error "Hubspot polling failed for user #{user.id}: #{e.message}"
    end
  end

  private

  def process_hubspot_contact(user, contact)
    contact_id = contact['id']
    props = contact['properties'] || {}

    # Determine if created or updated
    created_at = Time.parse(contact['createdAt']) rescue nil
    updated_at = Time.parse(contact['updatedAt']) rescue nil

    is_new = created_at && updated_at && (updated_at - created_at) < 60

    event_type = is_new ? 'hubspot_contact_created' : 'hubspot_contact_updated'

    # Format event data
    event_data = {
      contact_id: contact_id,
      email: props['email'],
      firstname: props['firstname'],
      lastname: props['lastname'],
      company: props['company'],
      phone: props['phone'],
      created_at: contact['createdAt'],
      updated_at: contact['updatedAt'],
      properties: props
    }

    Rails.logger.info "Processing Hubspot contact: #{props['email']} (#{event_type})"

    # Let AI agent decide what to do
    conversation = user.conversations.create(title: "Hubspot: #{props['email']}")
    agent = AiAgentService.new(user, conversation)
    response = agent.handle_webhook_event(event_type, event_data)

    # Log if AI took action
    unless response[:content] == 'NO_ACTION'
      Rails.logger.info "AI took action on Hubspot contact: #{response[:content]}"
    end

    # Also update knowledge base
    SyncSingleHubspotContactJob.perform_later(user.id, contact_id)

  rescue => e
    Rails.logger.error "Failed to process Hubspot contact #{contact_id}: #{e.message}"
  end
end
