class User < ApplicationRecord
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true

  has_many :oauth_credentials
  has_many :integrations_data, dependent: :destroy
  has_many :knowledge_entries, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :messages, through: :conversations
  has_many :ongoing_instructions, dependent: :destroy
  has_many :tasks, dependent: :destroy

  def self.from_omniauth(access_token)
    user = User.find_or_create_by(email: access_token.info.email) do |u|
      u.name = access_token.info.name
    end

    cred = user.oauth_credentials.find_or_initialize_by(provider: access_token.provider)
    cred.update!(
      provider_uid: access_token.uid,
      access_token: access_token.credentials.token,
      refresh_token: access_token.credentials.refresh_token,
      expires_at: Time.at(access_token.credentials.expires_at),
      raw: access_token.to_hash
    )

    user
  end

  def self.from_hubspot(user, token_response, portal_id)
    cred = user.oauth_credentials.find_or_initialize_by(provider: "hubspot")

    cred.update!(
      access_token: token_response['access_token'],
      refresh_token: token_response['refresh_token'],
      expires_at: Time.now + token_response['expires_in'].seconds,
      provider_uid: portal_id
    )
  end

  def google_client
    @google_client ||= GoogleApiClient.new(self)
  end

  def google_access_token
    google_oauth2_provider.access_token
  end

  def google_refresh_token
    google_oauth2_provider.refresh_token
  end

  def google_token_expires_at
    google_oauth2_provider.expires_at
  end

  def google_oauth2_provider
    @google_oauth2_provider ||= oauth_credentials.find_by(provider: "google_oauth2")
  end

  def hubspot_client
    @hubspot_client ||= HubspotApiClient.new(self)
  end

  def hubspot_access_token
    hubspot_provider&.access_token
  end

  def hubspot_refresh_token
    hubspot_provider.refresh_token
  end

  def hubspot_token_expires_at
    hubspot_provider.expires_at
  end

  def hubspot_provider
    @hubspot_provider ||= oauth_credentials.find_by(provider: "hubspot")
  end
end
