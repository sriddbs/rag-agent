class PollCalendarJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    return unless user.google_access_token.present?

    calendar = user.google_client.calendar_service

    # Get timestamp for last check
    last_check = user.last_calendar_check_at || 5.minutes.ago

    begin
      # Get events updated since last check
      events = calendar.list_events(
        'primary',
        updated_min: last_check.iso8601,
        single_events: true,
        order_by: 'updated',
        max_results: 50
      )

      return unless events.items.any?

      Rails.logger.info "Found #{events.items.count} calendar changes for user #{user.id}"

      events.items.each do |event|
        process_calendar_event(user, event)
      end

      # Update last check timestamp
      user.update!(last_calendar_check_at: Time.now)

    rescue Google::Apis::Error => e
      Rails.logger.error "Calendar polling failed for user #{user.id}: #{e.message}"
    end
  end

  private

  def process_calendar_event(user, event)
    # Determine event type
    event_type = case event.status
                 when 'cancelled'
                   'calendar_event_cancelled'
                 else
                   event.created == event.updated ? 'calendar_event_created' : 'calendar_event_updated'
                 end

    # Format event data
    event_data = {
      event_id: event.id,
      summary: event.summary || 'No title',
      description: event.description,
      start: event.start&.date_time || event.start&.date,
      end: event.end&.date_time || event.end&.date,
      attendees: event.attendees&.map(&:email) || [],
      status: event.status,
      created_at: event.created,
      updated_at: event.updated
    }
    
    Rails.logger.info "Processing calendar event: #{event.summary} (#{event_type})"

    # Let AI agent decide what to do
    conversation = user.conversations.create(title: "Calendar: #{event.summary}")
    agent = AiAgentService.new(user, conversation)
    response = agent.handle_webhook_event(event_type, event_data)
    
    # Log if AI took action
    unless response[:content] == 'NO_ACTION'
      Rails.logger.info "AI took action on calendar event: #{response[:content]}"
    end

  rescue => e
    Rails.logger.error "Failed to process calendar event #{event.id}: #{e.message}"
  end
end
