class User < ApplicationRecord
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true

  has_many :oauth_credentials

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
end
