class ToolRegistry
  # Map function names to executor classes
  TOOL_EXECUTORS = {
    'search_emails' => ToolExecutors::SearchEmails,
    'send_email' => ToolExecutors::SendEmail,
    'search_calendar' => ToolExecutors::SearchCalendar,
    'create_calendar_event' => ToolExecutors::CreateCalendarEvent,
    'search_hubspot_contacts' => ToolExecutors::SearchHubspotContacts,
    'create_hubspot_contact' => ToolExecutors::CreateHubspotContact,
    'update_hubspot_contact' => ToolExecutors::UpdateHubspotContact,
    'add_hubspot_note' => ToolExecutors::AddHubspotNote,
    'create_ongoing_instruction' => ToolExecutors::CreateOngoingInstruction,
    'get_available_calendar_slots' => ToolExecutors::GetAvailableCalendarSlots
  }.freeze

  def self.all_tools
    ToolSchemas::ALL_TOOLS
  end

  def self.execute(user, function_name, arguments)
    executor_class = TOOL_EXECUTORS[function_name]

    unless executor_class
      return {
        success: false,
        error: "Unknown tool: #{function_name}"
      }
    end

    executor = executor_class.new(user)
    executor.execute(arguments)
  rescue => e
    Rails.logger.error "Tool execution error in #{function_name}: #{e.message}\n#{e.backtrace.join("\n")}"
    {
      success: false,
      error: "Tool execution failed: #{e.message}"
    }
  end
end
