module ToolExecutors
  class AddHubspotNote
    def initialize(user)
      @user = user
    end

    def execute(args)
      client = @user.hubspot_client

      note = client.create_note(
        contact_id: args['contact_id'],
        note: args['note']
      )

      {
        success: true,
        message: "Note added to contact",
        data: { note_id: note['id'] }
      }
    rescue => e
      { success: false, message: "Failed to add note: #{e.message}" }
    end
  end
end
