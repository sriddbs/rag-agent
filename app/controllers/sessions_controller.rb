class SessionsController < ApplicationController
  def new
  end

  def callback
    user = User.from_omniauth(request.env["omniauth.auth"])
    session[:user_id] = user.id

    # Start initial sync
    SyncIntegrationsJob.perform_later(user.id)

    redirect_to root_path, notice: "Welcome, #{user.name || user.email}!"
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path, notice: 'Logged out successfully.'
  end
end
