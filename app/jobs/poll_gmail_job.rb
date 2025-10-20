class PollGmailJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    return unless user.google_access_token.present?

    gmail = user.google_client.gmail_service

    # Get timestamp for last check (default to 5 minutes ago)
    last_check = user.last_email_check_at || 5.minutes.ago

    # Convert to Gmail query format (seconds since epoch)
    after_timestamp = last_check.to_i

    begin
      # Search for messages after last check
      result = gmail.list_user_messages(
        'me',
        q: "after:#{after_timestamp}",
        max_results: 50
      )

      return unless result.messages

      Rails.logger.info "Found #{result.messages.count} new emails for user #{user.id}"
      
      result.messages.each do |message_ref|
        process_new_email(user, gmail, message_ref.id)
      end

      # Update last check timestamp
      user.update!(last_email_check_at: Time.now)
      
    rescue Google::Apis::Error => e
      Rails.logger.error "Gmail polling failed for user #{user.id}: #{e.message}"
    end
  end

  private

  def process_new_email(user, gmail, message_id)
    # Skip if already processed
    return if user.integrations_data.exists?(
      integration_type: 'gmail',
      external_id: message_id
    )

    # Get full message
    message = gmail.get_user_message('me', message_id)

    # Extract email details
    subject = get_header(message, 'Subject')
    from = get_header(message, 'From')
    snippet = message.snippet || ''

    # Format event data
    event_data = {
      message_id: message_id,
      from: from,
      subject: subject,
      snippet: snippet,
      thread_id: message.thread_id,
      received_at: Time.now.iso8601
    }

    Rails.logger.info "Processing new email: #{subject} from #{from}"

    # Let AI agent decide what to do
    conversation = user.conversations.create(title: "Email: #{subject}")
    agent = AiAgentService.new(user, conversation)
    response = agent.handle_webhook_event('gmail_message', event_data)
    
    # Log in conversation if AI took action
    unless response[:content] == 'NO_ACTION'
      Rails.logger.info "AI took action on email: #{response[:content]}"
    end

    # Also sync to knowledge base (background)
    SyncSingleEmailJob.perform_later(user.id, message_id)

  rescue => e
    Rails.logger.error "Failed to process email #{message_id}: #{e.message}"
  end

  def get_header(message, name)
    header = message.payload.headers.find { |h| h.name.downcase == name.downcase }
    header&.value || ''
  end
end
