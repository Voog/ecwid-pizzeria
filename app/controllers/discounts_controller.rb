require 'ecwid_api'

class DiscountsController < ApplicationController

  skip_before_action :verify_authenticity_token

  def show
    if EcwidPizzeria::Application.config.app.ecwid.api3_api_enabled
      client = EcwidApi::Client.new(EcwidPizzeria::Application.config.app.ecwid.shop_id, EcwidPizzeria::Application.config.app.ecwid.api3_access_token)
      result = EcwidApi::PagedEcwidResponse.new(client, 'discount_coupons', availability: 'ACTIVE', code: params[:id], limit: 1).first

      if result.present?
        render json: result
      else
        render json: {message: 'Not found.'}, status: :not_found
      end
    else
      render json: {message: 'Not enabled.'}, status: :not_implemented
    end
  rescue Exception => e
    Rails.logger.error "--- DiscountsController#show ERROR - code:#{params[:code]}: #{e.message.inspect}: \n#{e.backtrace[0..8].join("\n  ")}"
    render json: {message: 'Internal server error.'}, status: :internal_server_error
  end
end
