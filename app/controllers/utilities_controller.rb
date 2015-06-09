class UtilitiesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def ip
    render json: {ip: request.remote_ip}
  end
end