module ToolExecutors
  class CreateCalendarEvent
    def initialize(user)
      @user = user
    end

    def execute(args)
      calendar = @user.google_client.calendar_service

      event = Google::Apis::CalendarV3::Event.new(
        summary: args['summary'],
        description: args['description'],
        start: {
          date_time: args['start_time'],
          time_zone: 'America/Los_Angeles'
        },
        end: {
          date_time: args['end_time'],
          time_zone: 'America/Los_Angeles'
        },
        attendees: args['attendees']&.map { |email| { email: email } }
      )

      result = calendar.insert_event('primary', event, send_notifications: true)

      {
        success: true,
        message: "Calendar event created: #{args['summary']}",
        data: {
          event_id: result.id,
          summary: result.summary,
          start: result.start.date_time
        }
      }
    rescue => e
      { success: false, message: "Failed to create event: #{e.message}" }
    end
  end
end
