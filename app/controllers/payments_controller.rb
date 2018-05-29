class PaymentsController < ApplicationController

  skip_before_action :verify_authenticity_token
  before_action :prepare_payment
  before_action :set_selected_provider

  def create
    if @selected_provider.blank?
      # Prepare all enabled providers - for user desision
      prepare_all_providers
    elsif params[:provider] == 'makecommerce' && @payment_method.present?
      # Handle preselected MakeCommerce
      # Prepare MakeCommerce transaction and get settings
      @payment_request_settings = makecommerce_service.payment_request_settings(@payment)
      prepare_makecommerce

      if @payment_request_settings[:payment_flow] == 'redirect_url'
        # Redirect in case of redirect url
        redirect_to @payment_request_settings[:url]
      end
    end
  end

  private

  def calculate_request_mac(mac_input)
    if File.file?(EcwidPizzeria::Application.config.estcard.file_key)
      private_key = File.read(EcwidPizzeria::Application.config.estcard.file_key)
      OpenSSL::PKey::RSA.new(private_key).sign(OpenSSL::Digest::SHA1.new, mac_input).unpack('H*').first
    else
      Rails.logger.error "PaymentsController.calculate_request_mac - EstCard private key (#{EcwidPizzeria::Application.config.estcard.file_cert}) not found!"
      ''
    end
  end

  # Prepare payment
  def prepare_payment
    @payment = if params[:payment_id].present? && params[:provider] =~ %r(\Amakecommerce_)
      # Load exiting payment by ID for MakeCommerce redirect
      Payment.created.find(params[:payment_id])
    else
      Payment.create!(
        order_id: params[:ord], description: params[:des], amount: params[:amt].gsub(/\s/, ''),
        frequency: params[:frq], customer_email: params[:ceml], return_path: params[:ret],
        opt: params[:opt], currency: 'EUR'
      )
    end
  end

  # Set and verify provider
  def set_selected_provider
    autodetect_selected_provider if params[:provider] == 'auto' && params[:ord].present?

    @selected_provider = case params[:provider]
    when 'estcard'
      if EcwidPizzeria::Application.config.estcard.enabled
        prepare_estcard
        params[:provider]
      end
    when 'paypal'
      if EcwidPizzeria::Application.config.paypal.enabled
        prepare_paypal
        params[:provider]
      end
    when %r(\Amakecommerce_(.*)\z)
      payment_method = $1
      @payment_method = payment_method

      @payment_method = if EcwidPizzeria::Application.config.make_commerce.enabled && makecommerce_service.enabled_payment_methods.include?(payment_method)
        params[:provider] = 'makecommerce'
        payment_method
      else
        nil
      end
      params[:provider]
    when *EcwidPizzeria::Application.config.banks.enabled
      prepare_ipizza
      params[:provider]
    end
  end

  # Allow payments auto detection
  def autodetect_selected_provider
    if EcwidPizzeria::Application.config.app.ecwid.order_api_enabled
      params[:provider]

      url = "https://app.ecwid.com/api/v1/#{EcwidPizzeria::Application.config.app.ecwid.shop_id}/orders"
      api_params = {secure_auth_key: EcwidPizzeria::Application.config.app.ecwid.order_api_key, order: params[:ord]}

      response = RestClient.get(url, params: api_params)
      order = JSON.parse(response)['orders'].first

      val = order['paymentMethod'].to_s.downcase.strip
      # Try to get customer country code from order
      params[:country_code] ||= order.fetch('billingPerson', {}).fetch('countryCode', nil) || order['customerCountryCodeByIP']

      params[:provider] = case val
      when *(EcwidPizzeria::Application.config.banks.enabled + ['estcard', 'paypal'])
        val
      when %r(\A(makecommerce|maksekeskus)(.*)\z)
        payment_method = $2.gsub(':', '').strip.parameterize.gsub('-', '_')
        "makecommerce_#{payment_method}"
      when %r(\A(#{EcwidPizzeria::Application.config.banks.enabled.join('|')}*?)\s(pank|bank)\z)
        $1
      when 'danskebank', 'dnb', 'danske', 'danske bank', 'danske pank'
        'sampo'
      end
    end
  rescue
    nil
  end

  def prepare_all_providers
    prepare_ipizza
    prepare_estcard
    prepare_paypal
    prepare_makecommerce
  end

  def prepare_ipizza
    @ipizza_payment = Ipizza::Payment.new(
      stamp: @payment.id, amount: @payment.amount, refnum: @payment.order_id,
      message: t('labels.payment.message', shop_name: EcwidPizzeria::Application.config.app.shop_name, order_id: @payment.order_id, payment_id: @payment.id).strip,
      currency: @payment.currency
    )
  end

  def prepare_estcard
    if EcwidPizzeria::Application.config.estcard.enabled
      @estcard_request = EstcardRequest.create!(
        action: 'gaf', ver: '002', merchant_id: EcwidPizzeria::Application.config.estcard.merchant_id,
        ecuno: @payment.id * 100_000,
        eamount: (@payment.amount * 100).to_i,
        cur: @payment.currency,
        datetime: @payment.created_at.strftime('%Y%m%d%H%M%S'),
        lang: I18n.locale.to_s
      )

      @estcard_request.mac = calculate_request_mac(@estcard_request.mac_input)
    end
  end

  def prepare_paypal
    if EcwidPizzeria::Application.config.paypal.enabled
      @paypal_payment = Paypal.new(
        invoice: @payment.id, amount: @payment.amount, custom: @payment.order_id,
        item_name: t('labels.payment.message', shop_name: EcwidPizzeria::Application.config.app.shop_name, order_id: @payment.order_id, payment_id: @payment.id).strip,
        email: @payment.customer_email, currency: @payment.currency
      )
    end
  end

  def prepare_makecommerce
    if EcwidPizzeria::Application.config.make_commerce.enabled
      @makecommerce = {
        enabled_methods: makecommerce_service.enabled_payment_methods
      }
    end
  end

  def makecommerce_service
    @makecommerce_service ||= ::MakeCommerce::Service.new(
      payment_method: @payment_method,
      country_code: params[:country_code] || 'EE',
      request_ip: request.remote_ip
    )
  end
end
