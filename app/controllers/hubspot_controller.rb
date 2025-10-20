class HubspotController < ApplicationController
  # before_action :authenticate_user!

  def hubspot_auth
    redirect_to hubspot_authorization_url, allow_other_host: true
  end

  def hubspot_callback
    token_response = exchange_hubspot_code(params[:code])
    
    # Get portal ID from Hubspot account info
    portal_id = fetch_hubspot_portal_id(token_response['access_token'])
    
    User.from_hubspot(current_user, token_response, portal_id)

    # Start syncing Hubspot data immediately
    # SyncHubspotJob.perform_later(current_user.id)
    
    redirect_to root_path, notice: 'Hubspot connected successfully! Syncing data...'
  rescue => e
    Rails.logger.error "Hubspot OAuth error: #{e.message}\n#{e.backtrace.join("\n")}"
    redirect_to root_path, alert: "Failed to connect Hubspot: #{e.message}"
  end

  def sync_data
    SyncIntegrationsJob.perform_later(current_user.id)
    render json: { message: 'Sync started' }
  end

  def disconnect_hubspot
    current_user.hubspot_provider.update!(
      access_token: nil,
      refresh_token: nil,
      expires_at: nil,
      provider_uid: nil
    )
    
    # Optionally delete Hubspot data
    current_user.knowledge_entries.where(source_type: ['hubspot_contact', 'hubspot_note']).destroy_all
    current_user.integrations_data.where(integration_type: 'hubspot').destroy_all
    
    redirect_to root_path, notice: 'Hubspot disconnected'
  end

  private

  def hubspot_authorization_url
    client_id = ENV.fetch("HUBSPOT_CLIENT_ID")
    redirect_uri = hubspot_callback_integrations_url
    scopes = %w[
      crm.objects.contacts.read
      crm.objects.contacts.write
      crm.objects.companies.read
      crm.objects.companies.write
      crm.schemas.contacts.read
      crm.schemas.companies.read
      crm.schemas.contacts.write
      crm.schemas.companies.write
      oauth
    ]
    
    "https://app.hubspot.com/oauth/authorize?" \
    "client_id=#{client_id}&" \
    "redirect_uri=#{CGI.escape(redirect_uri)}&" \
    "scope=#{scopes.join('%20')}"
  end

  def exchange_hubspot_code(code)
    response = HTTParty.post('https://api.hubapi.com/oauth/v1/token',
      body: {
        grant_type: 'authorization_code',
        client_id: ENV.fetch("HUBSPOT_CLIENT_ID"),
        client_secret: ENV.fetch("HUBSPOT_CLIENT_SECRET"),
        redirect_uri: hubspot_callback_integrations_url,
        code: code
      }
    )
    
    unless response.success?
      raise "Hubspot OAuth failed: #{response.body}"
    end
    
    JSON.parse(response.body)
  end

  def fetch_hubspot_portal_id(access_token)
    response = HTTParty.get(
      'https://api.hubapi.com/oauth/v1/access-tokens/' + access_token
    )
    
    if response.success?
      data = JSON.parse(response.body)
      data['hub_id'].to_s
    else
      nil
    end
  end
end
