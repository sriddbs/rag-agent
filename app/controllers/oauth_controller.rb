class OauthController < ActionController::API
  # /auth/:provider/callback
  def callback
    user = User.from_omniauth(request.env['omniauth.auth'])

    token = JwtService.issue(user_id: user.id)
    render json: { token: token, email: user.email }
  end
end
