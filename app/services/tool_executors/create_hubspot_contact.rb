module ToolExecutors
  class CreateHubspotContact
    def initialize(user)
      @user = user
    end

    def execute(args)
      client = @user.hubspot_client

      properties = {
        email: args['email'],
        firstname: args['firstname'],
        lastname: args['lastname'],
        phone: args['phone']
      }.compact

      contact = client.create_contact(properties)

      {
        success: true,
        message: "Contact created: #{args['email']}",
        data: { contact_id: contact['id'], email: args['email'] }
      }
    rescue => e
      { success: false, message: "Failed to create contact: #{e.message}" }
    end
  end
end
