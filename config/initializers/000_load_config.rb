require 'ostruct'

Figaro.require_keys('ECWIDSHOP_SECRET_KEY_BASE', 'ECWIDSHOP_PROVIDER_RETURN_HOST') if Rails.env.production?

EcwidPizzeria::Application.configure do
  # Application general configuration
  config.app = OpenStruct.new
  config.app.shop_name = ENV['ECWIDSHOP_SHOP_NAME'].presence || ''
  config.app.shop_external_url = if ENV['ECWIDSHOP_SHOP_EXTERNAL_URL'].present?
    ENV['ECWIDSHOP_SHOP_EXTERNAL_URL'].to_s =~ /\Ahttps?\:\/\/.*?\z/i ? ENV['ECWIDSHOP_SHOP_EXTERNAL_URL'] : "http://#{ENV['ECWIDSHOP_SHOP_EXTERNAL_URL']}"
  else
    ''
  end
  config.app.shop_external_host = URI.parse(config.app.shop_external_url).host || ''
  config.app.shop_external_return_url = if ENV['ECWIDSHOP_SHOP_EXTERNAL_RETURN_URL'].present?
    ENV['ECWIDSHOP_SHOP_EXTERNAL_RETURN_URL'].to_s =~ /\Ahttps?\:\/\/.*?\z/i ? ENV['ECWIDSHOP_SHOP_EXTERNAL_RETURN_URL'] : "http://#{ENV['ECWIDSHOP_SHOP_EXTERNAL_RETURN_URL']}"
  else
    config.app.shop_external_url
  end
  config.app.return_host = ENV['ECWIDSHOP_PROVIDER_RETURN_HOST']

  # Setup Ecwid Order API access
  config.app.ecwid = OpenStruct.new
  config.app.ecwid.shop_id = ENV['ECWIDSHOP_ECWID_SHOP_ID'].presence
  config.app.ecwid.order_api_key = ENV['ECWIDSHOP_ECWID_ORDER_API_KEY'].presence
  config.app.ecwid.order_api_enabled = config.app.ecwid.shop_id.present? && config.app.ecwid.order_api_key.present?
  # Setup Ecwid API v3 (http://api.ecwid.com)
  config.app.ecwid.api3_access_token = ENV['ECWIDSHOP_ECWID_API3_ACCESS_TOKEN'].presence
  config.app.ecwid.api3_api_enabled = config.app.ecwid.shop_id.present? && config.app.ecwid.api3_access_token.present?

  # Set certificates root
  config.app.certs_root = if ENV['ECWIDSHOP_CERTS_FULL_ROOT'].present? && Dir.exist?(ENV['ECWIDSHOP_CERTS_FULL_ROOT'])
    ENV['ECWIDSHOP_CERTS_FULL_ROOT']
  else
    Rails.root.join(ENV['ECWIDSHOP_CERTS_FOLDER'])
  end

  # Set default from and sender for emails
  config.app.mailer = OpenStruct.new(
    default_from: ENV['ECWIDSHOP_MAILER_DEFAULT_FROM'],
    notification_email: ENV['ECWIDSHOP_MAILER_NOTIFICATION_EMAIL']
  )

  # Allow to override default payment confirmation file subject and content
  config.app.payment_confirmation_email_subject = OpenStruct.new
  config.app.payment_confirmation_email_body = OpenStruct.new
  %w(en et).each do |locale|
    config.app.payment_confirmation_email_subject.send("#{locale}=", ENV["ECWIDSHOP_PAYMENT_CONFIRMATION_EMAIL_SUBJECT_#{locale.upcase}"] || '')
    config.app.payment_confirmation_email_body.send("#{locale}=", ENV["ECWIDSHOP_PAYMENT_CONFIRMATION_EMAIL_BODY_#{locale.upcase}"] || '')
  end

  # Set password and username for /admin pages
  config.app.authentication = OpenStruct.new(
    username: ENV['ECWIDSHOP_AUTHENTICATION_USERNAME'],
    password: ENV['ECWIDSHOP_AUTHENTICATION_PASSWORD']
  )

  # iPizza banks related configuration
  ipizza_conf = config_for(:banks)
  # Configure iPizza
  Ipizza::Config.configure do |c|
    c.certs_root = config.app.certs_root
    c.load_from_hash(ipizza_conf)
  end

  # Check and setup available and enabled banks information
  config.banks = OpenStruct.new(available: %w(swedbank seb lhv sampo krediidipank nordea), enabled: [])
  config.banks.available.each do |code|
    is_enabled = ENV["ECWIDSHOP_BANK_#{code.upcase}_ENABLED"].to_s.downcase == 'true'
    is_configured = File.file?(File.join(config.app.certs_root, ipizza_conf.fetch(code, {}).fetch('file_key', '')))
    config.banks.send("#{code}=", OpenStruct.new(enabled: is_enabled, configured: is_configured, settings: OpenStruct.new(ipizza_conf.fetch(code, {}))))
    config.banks.enabled << code if is_enabled && is_configured
  end

  # Load EstCard related configuration
  estcard_conf = ipizza_conf.fetch('estcard', {})
  config.estcard = OpenStruct.new(
    enabled: ENV['ECWIDSHOP_ESTCARD_ENABLED'].to_s.downcase == 'true',
    service_url: estcard_conf.fetch('service_url', ''),
    merchant_id: estcard_conf.fetch('merchant_id', ''),
    file_cert: File.join(config.app.certs_root, estcard_conf.fetch('file_cert', '')),
    file_key: File.join(config.app.certs_root, estcard_conf.fetch('file_key', ''))
  )

  # Setup email delivering
  config.action_mailer.delivery_method = ENV['ECWIDSHOP_MAILER_DELIVERY_METHOD'].downcase.to_sym if ENV['ECWIDSHOP_MAILER_DELIVERY_METHOD'].present?
  # Setup SMTP settings
  if config.action_mailer.delivery_method == :smtp
    config.action_mailer.smtp_settings = {
      address: ENV.fetch('ECWIDSHOP_SMTP_SERVER', 'localhost'),
      port: ENV.fetch('ECWIDSHOP_SMTP_SERVER_PORT', 25).to_i,
      domain: ENV.fetch('ECWIDSHOP_SMTP_DOMAIN', 'example.com')
    }.tap do |h|
      h[:enable_starttls_auto] = ENV['ECWIDSHOP_SMTP_ENABLE_STARTTLS_AUTO'].to_s.downcase == 'true' if ENV['ECWIDSHOP_SMTP_ENABLE_STARTTLS_AUTO'].present?
      h[:authentication] = ENV['ECWIDSHOP_SMTP_AUTHENTICATION'].to_sym if ENV['ECWIDSHOP_SMTP_AUTHENTICATION'].present?
      h[:user_name] = ENV['ECWIDSHOP_SMTP_USER_NAME'].presence
      h[:password] = ENV['ECWIDSHOP_SMTP_PASSWORD'].presence
    end
  end
end
