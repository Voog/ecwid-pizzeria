require 'uri'
require_dependency "#{Rails.root}/lib/make_commerce/api_client"

# MakeCommerce transaction preparation service
module MakeCommerce
  class Service
    CARD_METHODS = %w(visa mastercard maestro).freeze
    BANK_METHODS = %w(swedbank seb lhv nordea danske krediidipank pocopay liisi_ee citadele pohjola alandsbanken handelsbanken saastopankki spankki tapiola aktia omasaastopankki poppankki).freeze
    PAYMENT_METHODS = BANK_METHODS + CARD_METHODS

    attr_accessor :payment_method, :country_code, :language, :request_ip

    def initialize(payment_method: nil, country_code: nil, language: nil, request_ip: nil)
      @country_code = country_code
      @payment_method = payment_method
      @language = language
      @request_ip = request_ip
    end

    def all_payment_methods
      PAYMENT_METHODS
    end

    def supported_payment_methods
      @supported_payment_methods ||= begin
        PAYMENT_METHODS & (shop_payment_methods || []).map { |e| e[:name] }
      end
    end

    def enabled_payment_methods
      EcwidPizzeria::Application.config.make_commerce.enabled_methods & supported_payment_methods
    end

    # Service url (default: https://payment.maksekeskus.ee/pay/1/link.html)
    def service_url
      EcwidPizzeria::Application.config.make_commerce.service_url
    end

    # Service url for signed requests (default: https://payment.maksekeskus.ee/pay/1/signed.html)
    def service_signed_url
      EcwidPizzeria::Application.config.make_commerce.service_signed_url
    end

    # Api url (default: https://api.maksekeskus.ee/v1)
    def api_url
      EcwidPizzeria::Application.config.make_commerce.api_url
    end

    # Shop ID
    def shop_id
      EcwidPizzeria::Application.config.make_commerce.shop_id
    end

    # Shop API secret
    def api_secret
      EcwidPizzeria::Application.config.make_commerce.api_secret
    end

    # def settings
    #   @settings ||= gateway.try(:settings).is_a?(Hash) ? gateway.settings : {}
    # end

    # Return payments request settings
    def payment_request_settings(payment)
      url = payment_url_for_payment(payment)

      if url
        {
          url: url,
          payment_flow: 'redirect_url'
        }
      else
        {
          url: service_signed_url,
          payment_flow: 'redirect_form',
          attributes: payload_for_signed_request(payment)
        }
      end
    end

    # Signed payload for Payment Gateway (credit cards)
    # country_code and payment_method is required to select right payment method in redirected page.
    def payload_for_signed_request(payment)
      json = {
        shop: shop_id,
        amount: payment.amount,
        currency: payment.currency,
        reference: payment.order_id,
        country: @country_code,
        locale: @language,
        preferred_method: @payment_method
      }.to_json

      {
        json: json,
        mac: Digest::SHA512.hexdigest(json + api_secret).upcase
      }
    end

    # Payload for API transaction create request
    def payload_for_transaction(payment)
      {
        transaction: {
          amount: payment.amount,
          currency: payment.currency,
          reference: payment.order_id,
          merchant_data: "payment_id:#{payment.id}",
          transaction_url: {
            return_url: {
              url: EcwidPizzeria::Application.config.make_commerce.return_url,
              method: 'POST'
            },
            cancel_url: {
              url: EcwidPizzeria::Application.config.make_commerce.cancel_url,
              method: 'POST'
            },
            notification_url: {
              url: EcwidPizzeria::Application.config.make_commerce.notification_url,
              method: 'POST'
            }
          }
        },
        customer: {
          # email: "customer@email.com",
          ip: @request_ip,
          country: @country_code,
          locale: @language
        }
      }
    end

    # MakeCommerce API client
    def client
      @client ||= ::MakeCommerce::ApiClient.new(url: api_url, shop_id: shop_id, api_secret: api_secret)
    end

    # Get payment method hash with code and url.
    # Prepares transaction in MakeCommerse when the payment method is not credit card.
    def payment_url_for_payment(payment)
      if @payment_method.blank? || CARD_METHODS.include?(@payment_method)
        nil
      else
        existing_transaction = MakeCommerceRequest.where(payment_id: payment.id).last

        if existing_transaction.present?
          # Transaction has already been prepared in MakeCommerce environment
          # Load payment service url from shop enabled methods hash
          url = (payment_method_hash(shop_payment_methods, @payment_method, @country_code) || {})[:url]
          url_with_transaction(url, existing_transaction.external_transaction_key) if url.present?
        else
          # Prepare transaction in MakeCommerce environment
          transaction = client.create_transaction(payload_for_transaction(payment))

          if transaction.present? && transaction[:status] == 'CREATED'
            MakeCommerceRequest.where(payment_id: payment.id, external_transaction_key: transaction[:id], payment_method: @payment_method)
            # Load payment service url from transaction enabled methods hash
            (payment_method_hash(transaction[:payment_methods][:banklinks], @payment_method, @country_code) || {})[:url]
          end
        end
      end
    end

    # Get shop payment methods, enabled in gateway.
    def shop_payment_methods
      return unless client

      Rails.cache.fetch([cache_key, 'shop_payment_methods'].join('/'), expires_in: 1.hour) do
        client.normalized_payment_methods
      end
    end

    def expire_cache_keys!
      Rails.cache.delete([cache_key, 'shop_payment_methods'].join('/'))
      true
    end

    def cache_key
      ['gateway', 'make_commerce', shop_id].join('/')
    end

    private

    def payment_method_hash(arr, code, country_code)
      arr.detect { |h| h[:name] == code && h[:country] == country_code } || arr.detect { |h| h[:name] == code }
    end

    def url_with_transaction(url, transaction)
      parsed_url = URI.parse(url)

      query = URI.decode_www_form(parsed_url.query || '')
      query << ['trx', transaction]

      parsed_url.query = URI.encode_www_form(query)
      parsed_url.to_s
    end
  end
end
