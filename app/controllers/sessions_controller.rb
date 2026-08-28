class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  redirect_authenticated_users only: %i[new]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }
  layout "auth", only: %i[new]

  def new
  end

  def create
    user = User.find_by(email_address: params[:email_address])

    if user&.password_user? && user.authenticate(params[:password])
      start_new_session_for user
      redirect_to after_authentication_url, notice: "Welcome back!"
    else
      redirect_to new_session_path, alert: "Invalid email or password."
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, status: :see_other
  end
end
