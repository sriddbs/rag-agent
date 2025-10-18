class GoogleApiClient
  def initialize(user)
    @user = user
  end

  def gmail_service
    service = Google::Apis::GmailV1::GmailService.new
    service.authorization = authorization
    service
  end

  def calendar_service
    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = authorization
    service
  end

  private

  def authorization
    return @authorization if @authorization

    @authorization = Signet::OAuth2::Client.new(
      client_id: "756826802737-as4sit73u6dv2qh37kdcameohat59ebt.apps.googleusercontent.com",
      client_secret: "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",
      token_credential_uri: 'https://oauth2.googleapis.com/token',
      access_token: @user.google_access_token,
      refresh_token: @user.google_refresh_token,
      expires_at: @user.google_token_expires_at
    )

    if @authorization.expired?
      @authorization.refresh!
      @user.google_oauth2_provider.update!(
        access_token: @authorization.access_token,
        expires_at: @authorization.expires_at
      )
    end

    @authorization
  end
end
