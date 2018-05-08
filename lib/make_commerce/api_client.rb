require 'faraday'
require 'faraday_middleware'

# Basic MakeCommerce (https://makecommerce.net/) API wrapper
module MakeCommerce
  class ApiClient

    attr_reader :url, :shop_id, :api_secret, :last_response

    def initialize(options = {})
      @url = options.fetch(:url)
      @shop_id = options.fetch(:shop_id)
      @api_secret = options.fetch(:api_secret)
    end

    def client
      @client ||= Faraday.new(url: url) do |conn|
        conn.use Faraday::Request::BasicAuthentication, shop_id, api_secret
        conn.request :json
        conn.response :json, content_type: /\bjson$/
        conn.adapter Faraday.default_adapter
      end
    end

    # Get shop configuration
    # https://developer.maksekeskus.ee//reference.php#get-configuration
    def shop_configuration
      @shop_configuration ||= begin
        @last_response = client.get('shop/configuration', environment: req_environment.to_json)
        if @last_response.success?
          @last_response.body.with_indifferent_access
        else
          {}
        end
      end
    end

    # Get enabled payment methods for shop
    def payment_methods
      shop_configuration[:payment_methods].presence || []
    end

    # Get enabled payment methods for shop and normalize the output
    def normalized_payment_methods
      payment_methods.map { |_, v| v.presence }.compact.flatten
    end

    # https://developer.maksekeskus.ee/transaction.php
    def create_transaction(data)
      @last_response = client.post('transactions', data)
      if @last_response.success?
        @last_response.body.with_indifferent_access
      else
        {}
      end
    end

    private

    def req_environment
      {platform: 'Ecwid Pizzeria', module: 'makecommerce'}
    end
  end
end
