module ToolExecutors
  class SearchCalendar
    def initialize(user)
      @user = user
    end

    def execute(args)
      calendar = @user.google_client.calendar_service

      start_date = args['start_date'] || Time.now.iso8601
      end_date = args['end_date'] || (Time.now + 30.days).iso8601

      events = calendar.list_events(
        'primary',
        time_min: start_date,
        time_max: end_date,
        max_results: 50,
        single_events: true,
        order_by: 'startTime'
      )

      {
        success: true,
        message: "Found #{events.items.count} events",
        data: events.items.map do |event|
          {
            summary: event.summary,
            start: event.start.date_time || event.start.date,
            end: event.end.date_time || event.end.date,
            attendees: event.attendees&.map(&:email) || []
          }
        end
      }
    rescue => e
      { success: false, message: "Failed to search calendar: #{e.message}" }
    end
  end
end
