require 'rails_helper'

RSpec.describe User, type: :model do
  describe ".from_omniauth" do
    let(:email) { "john@example.com" }
    let(:provider) { "google_oauth2" }
    let(:uid) { "12345" }
    let(:token) { "token-abc" }
    let(:refresh_token) { "refresh-xyz" }
    let(:expires_at) { 2.hours.from_now.to_i }

    # Build a fake OmniAuth hash that looks like the real one
    let(:access_token) do
      OmniAuth::AuthHash.new(
        provider: provider,
        uid: uid,
        info: OmniAuth::AuthHash.new(email: email, name: "John Doe"),
        credentials: OmniAuth::AuthHash.new(
          token: token,
          refresh_token: refresh_token,
          expires_at: expires_at
        )
      )
    end

    it "creates a new user and oauth_credential" do
      expect {
        described_class.from_omniauth(access_token)
      }.to change(User, :count).by(1)
        .and change(OauthCredential, :count).by(1)

      user = User.find_by(email: email)
      cred = user.oauth_credentials.last

      expect(user.name).to eq("John Doe")
      expect(cred.provider).to eq(provider)
      expect(cred.provider_uid).to eq(uid)
      expect(cred.access_token).to eq(token)
      expect(cred.refresh_token).to eq(refresh_token)
      expect(cred.expires_at.to_i).to eq(Time.at(expires_at).to_i)
    end

    it "updates the existing credential" do
      user = create(:user, email: email, name: "Old Name")
      cred = user.oauth_credentials.create!(provider: provider, access_token: "old", refresh_token: "old")

      expect {
        described_class.from_omniauth(access_token)
      }.not_to change(User, :count)

      cred.reload
      expect(cred.access_token).to eq(token)
      expect(cred.refresh_token).to eq(refresh_token)
      expect(cred.provider_uid).to eq(uid)
    end
  end
end
