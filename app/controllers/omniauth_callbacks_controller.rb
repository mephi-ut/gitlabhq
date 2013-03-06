class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # Authentication providers
  Gitlab.config.authentication.providers.each_pair do |provider, args|
    if args['enabled']
      define_method provider do
        handle_omniauth_authentication
      end
    end
  end

  # OAuth providers
  Gitlab.config.oauth.providers.each do |provider|
    define_method provider['name'] do
      handle_oauth
    end
  end

  # Extend the standard message generation to accept our custom exception
  def failure_message
    exception = env["omniauth.error"]
    error   = exception.error_reason if exception.respond_to?(:error_reason)
    error ||= exception.error        if exception.respond_to?(:error)
    error ||= exception.message      if exception.respond_to?(:message)
    error ||= env["omniauth.error.type"].to_s
    error.to_s.humanize if error
  end

  def ldap
    # We only find ourselves here if the authentication to LDAP was successful.
    @user = User.find_for_ldap_auth(request.env["omniauth.auth"], current_user)
    if @user.persisted?
      @user.remember_me = true
    end
    sign_in_and_redirect @user
  end

  private

  def handle_omniauth_authentication
    auth = request.env['omniauth.auth']
    @user = User.find_or_new_for_omniauth(auth)

    if @user
      sign_in_and_redirect @user
    else
      # TODO: There is no way to disable single sign on, so we never come here
      flash[:notice] = "Single sign on is not enabled!"
      redirect_to new_user_session_path
    end
  end

  def handle_oauth
    oauth = request.env['omniauth.auth']
    provider, uid = oauth['provider'], oauth['uid']

    if current_user
      # Change a logged-in user's authentication method:
      current_user.extern_uid = uid
      current_user.provider = provider
      current_user.save
      redirect_to profile_path
    else
      @user = User.find_or_new_for_omniauth(oauth)

      if @user
        sign_in_and_redirect @user
      else
        flash[:notice] = "There's no such user!"
        redirect_to new_user_session_path
      end
    end
  end
end
