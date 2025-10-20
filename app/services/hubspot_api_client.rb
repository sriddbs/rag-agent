require "httparty"

class HubspotApiClient
  def initialize(user)
    @user = user
    @base_url = 'https://api.hubapi.com'
  end

  def create_contact(properties)
    response = HTTParty.post(
      "#{@base_url}/crm/v3/objects/contacts",
      headers: headers,
      body: { properties: properties }.to_json
    )
    JSON.parse(response.body)
  end

  def search_contacts(query)
    response = HTTParty.post(
      "#{@base_url}/crm/v3/objects/contacts/search",
      headers: headers,
      body: {
        filterGroups: [{
          filters: [{
            propertyName: 'email',
            operator: 'CONTAINS_TOKEN',
            value: query
          }]
        }]
      }.to_json
    )
    JSON.parse(response.body)
  end

  def create_note(contact_id:, note:)
    response = HTTParty.post(
      "#{@base_url}/crm/v3/objects/notes",
      headers: headers,
      body: {
        properties: {
          hs_note_body: note,
          hs_timestamp: Time.now.to_i * 1000
        },
        associations: [{
          to: { id: contact_id },
          types: [{ associationCategory: 'HUBSPOT_DEFINED', associationTypeId: 202 }]
        }]
      }.to_json
    )
    JSON.parse(response.body)
  end

  def get_all_contacts
    response = HTTParty.get(
      "#{@base_url}/crm/v3/objects/contacts",
      headers: headers,
      query: { limit: 100 }
    )
    JSON.parse(response.body)
  end

  def search_recently_modified_contacts(since_timestamp_ms)
    response = HTTParty.post(
      "#{@base_url}/crm/v3/objects/contacts/search",
      headers: headers,
      body: {
        filterGroups: [{
          filters: [{
            propertyName: 'hs_lastmodifieddate',
            operator: 'GTE',
            value: since_timestamp_ms.to_s
          }]
        }],
        properties: %w[email firstname lastname phone company jobtitle lifecyclestage],
        limit: 100,
        sorts: [{
          propertyName: 'hs_lastmodifieddate',
          direction: 'DESCENDING'
        }]
      }.to_json
    )
    JSON.parse(response.body)
  end

  private

  def headers
    {
      'Authorization' => "Bearer #{access_token}",
      'Content-Type' => 'application/json'
    }
  end

  def access_token
    if @user.hubspot_token_expires_at < Time.now
      refresh_token!
    end
    @user.hubspot_access_token
  end

  def refresh_token!
    response = HTTParty.post(
      'https://api.hubapi.com/oauth/v1/token',
      body: {
        grant_type: 'refresh_token',
        client_id: ENV.fetch("HUBSPOT_CLIENT_ID"),
        client_secret: ENV.fetch("HUBSPOT_CLIENT_SECRET"),
        refresh_token: @user.hubspot_refresh_token
      }
    )

    data = JSON.parse(response.body)
    @user.hubspot_provider.update!(
      access_token: data['access_token'],
      expires_at: Time.now + data['expires_in'].seconds
    )
  end
end
