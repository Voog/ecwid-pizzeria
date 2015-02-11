class Admin::AdminController < ApplicationController

  before_action :authenticate

  layout 'admin/application'

  def app_settings
    @app_conf = EcwidPizzeria::Application.config.app
    @banks_conf = EcwidPizzeria::Application.config.banks
    @estcard_conf = EcwidPizzeria::Application.config.estcard
    @mailer_conf = EcwidPizzeria::Application.config.action_mailer
  end

  private

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      EcwidPizzeria::Application.config.app.authentication.username.present? &&
        username == EcwidPizzeria::Application.config.app.authentication.username &&
        password == EcwidPizzeria::Application.config.app.authentication.password
    end
  end
end
