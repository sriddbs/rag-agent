module ToolExecutors
  class GetAvailableCalendarSlots
    def initialize(user)
      @user = user
    end

    def execute(args)
      calendar = @user.google_client.calendar_service

      start_date = args['start_date'] || Time.now.iso8601
      end_date = args['end_date'] || (Time.now + 7.days).iso8601
      duration = args['duration_minutes'] || 30

      # Get existing events
      events = calendar.list_events(
        'primary',
        time_min: start_date,
        time_max: end_date,
        single_events: true,
        order_by: 'startTime'
      )

      # Find available slots
      available_slots = find_available_slots(
        events.items,
        Time.parse(start_date),
        Time.parse(end_date),
        duration
      )

      {
        success: true,
        message: "Found #{available_slots.count} available slots",
        data: {
          slots: available_slots.map do |slot|
            {
              start: slot[:start].iso8601,
              end: slot[:end].iso8601,
              duration_minutes: duration
            }
          end
        }
      }
    rescue => e
      { success: false, message: "Failed to get available slots: #{e.message}" }
    end

    private

    def find_available_slots(events, start_time, end_time, duration_minutes)
      # Business hours: 9 AM to 5 PM, Monday-Friday
      available_slots = []
      current_time = start_time

      while current_time < end_time
        # Skip weekends
        if current_time.wday.in?([0, 6])
          current_time = current_time.beginning_of_day + 1.day + 9.hours
          next
        end

        # Set to business hours
        if current_time.hour < 9
          current_time = current_time.change(hour: 9, min: 0)
        elsif current_time.hour >= 17
          current_time = current_time.beginning_of_day + 1.day + 9.hours
          next
        end

        slot_end = current_time + duration_minutes.minutes

        # Check if slot conflicts with existing events
        unless conflicts_with_events?(current_time, slot_end, events)
          available_slots << { start: current_time, end: slot_end }
        end

        # Move to next 30-minute slot
        current_time += 30.minutes

        # Stop after finding 10 slots
        break if available_slots.count >= 10
      end

      available_slots
    end

    def conflicts_with_events?(slot_start, slot_end, events)
      events.any? do |event|
        event_start = event.start.date_time || Time.parse(event.start.date.to_s)
        event_end = event.end.date_time || Time.parse(event.end.date.to_s)

        # Check for overlap
        slot_start < event_end && slot_end > event_start
      end
    end
  end
end
