module ToolExecutors
  class UpdateHubspotContact
    def initialize(user)
      @user = user
    end

    def execute(args)
      client = @user.hubspot_client

      properties = args.slice('email', 'firstname', 'lastname', 'phone', 'company', 'jobtitle')
                       .compact

      contact = client.update_contact(args['contact_id'], properties)

      {
        success: true,
        message: "Contact updated successfully",
        data: { contact_id: args['contact_id'], updated_fields: properties.keys }
      }
    rescue => e
      { success: false, message: "Failed to update contact: #{e.message}" }
    end
  end
end
