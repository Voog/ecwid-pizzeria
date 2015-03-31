class PaymentsController < ApplicationController

  skip_before_action :verify_authenticity_token
  before_action :set_selected_provider

  def create
    @payment = Payment.create!(
      order_id: params[:ord], description: params[:des], amount: params[:amt].gsub(/\s/, ''),
      frequency: params[:frq], customer_email: params[:ceml], return_path: params[:ret],
      opt: params[:opt], currency: 'EUR'
    )

    @ipizza_payment = Ipizza::Payment.new(
      stamp: @payment.id, amount: @payment.amount, refnum: @payment.order_id,
      message: t('labels.payment.message', shop_name: EcwidPizzeria::Application.config.app.shop_name, order_id: @payment.order_id, payment_id: @payment.id).strip,
      currency: @payment.currency
    )

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

  def set_selected_provider
    autodetect_selected_provider if params[:provider] == 'auto' && params[:ord].present?

    @selected_provider = case params[:provider]
    when 'estcard'
      params[:provider] if EcwidPizzeria::Application.config.estcard.enabled
    when *EcwidPizzeria::Application.config.banks.enabled
      params[:provider]
    end
  end

  # Allow payments auto detection
  def autodetect_selected_provider
    Rails.logger.debug "==="
    if EcwidPizzeria::Application.config.app.ecwid.order_api_enabled
      params[:provider]

      url = "https://app.ecwid.com/api/v1/#{EcwidPizzeria::Application.config.app.ecwid.shop_id}/orders"
      api_params = {secure_auth_key: EcwidPizzeria::Application.config.app.ecwid.order_api_key, order: params[:ord]}
      order = RestClient.get(url, params: api_params)
      val = JSON.parse(order)['orders'].first['paymentMethod'].to_s.downcase.strip

      params[:provider] = case val
      when *(EcwidPizzeria::Application.config.banks.enabled + ['estcard'])
        val
      when %r(\A(#{EcwidPizzeria::Application.config.banks.enabled.join('|')}*?)\s(pank|bank)\z)
        $1
      when 'danskebank', 'dnb', 'danske', 'danske bank', 'danske pank'
        'sampo'
      end
    end
  rescue
    nil
  end
end
