class Payment < ActiveRecord::Base

  module Status
    Cancelled = 'cancelled'
    Created = 'created'
    Delivered = 'delivered'
  end

  validates :order_id, :amount, presence: true

  before_validation :set_status, on: :create

  scope :created, -> { where(status: Status::Created)}

  def delivered?
    Status::Delivered == status
  end

  def deliver!
    update_attribute(:status, Status::Delivered)
  end

  def cancelled?
    Status::Cancelled == status
  end

  def cancel!
    update_attribute(:status, Status::Cancelled)
  end

  # Return url for customer
  def store_return_url
    if EcwidPizzeria::Application.config.app.ecwid.order_api_enabled
      # When Ecwid API is configured then delivering/cancelling notification is sent over API.
      # So we redirect user back to shop site Ecwid checkout page if external shop url is present
      if EcwidPizzeria::Application.config.app.shop_external_return_url.present?
        if opt.present?
          if delivered?
            "#{EcwidPizzeria::Application.config.app.shop_external_return_url}#!/~/checkoutResult/#{opt_to_param}"
          elsif cancelled?
            "#{EcwidPizzeria::Application.config.app.shop_external_return_url}#cancelled"
          end
        else
          EcwidPizzeria::Application.config.app.shop_external_return_url
        end
      end
    else
      # If Ecwid API is not enabled then redirect user back to ePath url if payment is delivered
      delivered? ? return_path : EcwidPizzeria::Application.config.app.shop_external_return_url
    end
  end

  def send_store_notification!(opt = {})
    retry_attempt = opt.fetch(:retry_attempt, 1)

    if EcwidPizzeria::Application.config.app.ecwid.order_api_enabled
      if delivered? || cancelled?
        url = "https://app.ecwid.com/api/v1/#{EcwidPizzeria::Application.config.app.ecwid.shop_id}/orders"
        params = {
          secure_auth_key: EcwidPizzeria::Application.config.app.ecwid.order_api_key,
          order: order_id,
          new_payment_status: (delivered? ? 'ACCEPTED' : 'CANCELLED')
        }

        begin
          exec_notification_request(url, params)
        rescue RestClient::RequestTimeout, RestClient::TooManyRequests
          Rails.logger.warn "WARNING: Payment.send_store_notification! got timeout. #{'Tying once more.' if retry_attempt < 3} Retry_attempt: #{retry_attempt} Payment id: #{id}, order_id: #{order_id}, status: #{status}"
          if retry_attempt < 3
            sleep 10 * retry_attempt
            send_store_notification!(retry_attempt: retry_attempt + 1)
          end
        end
      end
    else
      Rails.logger.warn 'Ecwid Order API is not enabled!'
    end
  rescue Exception => e
    Rails.logger.error "ERROR: Payment.send_store_notification! was failed. Payment id: #{id}, order_id: #{order_id}, status: #{status}: #{e.message.inspect}: \n#{e.backtrace[0..8].join("\n  ")}"
  end

  private

  def opt_to_param
    'id=%s&tc=%s' % opt.to_s.split(';')
  rescue
    ''
  end

  def exec_notification_request(url, params)
    if Rails.env.production?
      RestClient.post(url, params, accept: :json)
    else
      RestClient.get(url, params: params.merge(debug: 'yes'))
    end
  end

  def set_status
    write_attribute(:status, Status::Created) if status.blank?
  end
end
