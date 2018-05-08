# MakeCommerce notification parsing service
module MakeCommerce
  class ParsingService
    attr_accessor :payload, :message

    def initialize(payload: nil, system_notificaton: false, cancelled_by_customer: false, returned_by_customer: false)
      @payload = payload

      @system_notificaton = system_notificaton
      @cancelled_by_customer = cancelled_by_customer
      @returned_by_customer = returned_by_customer

      prepare_payload
    end

    # Create MakeCommerceMessage object
    def handle!
      create_message_from_payload!
    end

    def api_secret
      EcwidPizzeria::Application.config.make_commerce.api_secret
    end

    # Message type. Read more https://maksekeskus.ee/api-explorer/messages.php
    def message_type
      @message_type ||= payload[:json][:message_type] if payload[:json].present?
    end

    def payment_message?
      message_type == 'payment_return'
    end

    def token_message?
      message_type == 'token_return'
    end

    # Exctract custom merchant data from request
    def merchant_data
      @merchant_data ||= if payload[:json].present? && payload[:json][:merchant_data].present?
        payload[:json][:merchant_data].split(';').each_with_object({}) do |e, h|
          k, v = e.split(':')
          h[k.to_sym] = v
        end
      else
        {}
      end
    end

    # Is the notification sent from system to system or is is triggered by user action (return).
    def system_notificaton?
      @system_notificaton
    end

    # Notification is triggered by user (clicked on cancel url)
    def cancelled_by_customer?
      @cancelled_by_customer
    end

    # Notification is triggered by user (clicked on return url)
    def returned_by_customer?
      @returned_by_customer
    end

    def prepare_payload
      @payload = payload.merge(validation_status: validation_status)
      @payload[:json] = {} if @payload[:json].blank?

      return unless @payload[:json].is_a?(String)

      @payload[:json] = begin
        JSON.parse(@payload[:json]).with_indifferent_access if payload[:json].present?
      rescue => e
        Rails.logger.error "ERROR: MakeCommerce::ParsingService.prepare_payload. #{e.message.inspect}: \n#{e.backtrace[0..8].join("\n  ")}"
        {}
      end
    end

    # Get order reference from payload
    def payment_id
      @payment_id ||= if payment_message?
        merchant_data.fetch(:payment_id, payload.fetch(:payment_id, nil))
      elsif token_message?
        payload.fetch(:payment_id, nil)
      end
    end

    def transaction_id
      @transaction_id ||= if payment_message?
        payload[:json][:transaction]
      elsif token_message?
        payload[:json].fetch(:transaction, {})[:id]
      end
    end

    def notification_amount
      @notification_amount ||= payload[:json][:amount] if payment_message?
    end

    def notification_currency
      @notification_currency ||= payload[:json][:currency] if payment_message?
    end

    def payment
      @payment ||= if payment_id.present?
        ::Payment.find_by(payment_id)
      elsif payload[:json][:reference].present?
        ::Payment.where(order_id: payload[:json][:reference]).last
      end
    end

    def verified_request?
      validation_status == 'valid'
    end

    def gateway_status
      return unless verified_request?

      if payment_message?
        payload[:json][:status]
      elsif token_message?
        payload[:json].fetch(:transaction, {})[:status]
      end
    end

    # Validate the payload against the MAC value
    def validation_status
      return nil if cancelled_by_customer?

      @validation_status ||= if payload[:raw_post].present? && payload[:mac].present? && valid_notification_data?(payload[:raw_post], payload[:mac])
        'valid'
      else
        'failed'
      end
    end

    # Get unified status of the notification
    # See also https://maksekeskus.ee/arendajale/state-models/
    def status_for_notification
      return ::MakeCommerceMessage::AppStatus::Cancelled if cancelled_by_customer?
      return ::MakeCommerceMessage::AppStatus::Invalid if gateway_status.blank?

      case gateway_status
      when 'COMPLETED'
        ::MakeCommerceMessage::AppStatus::Success
      when 'PENDING', 'CREATED', 'APPROVED'
        ::MakeCommerceMessage::AppStatus::Pending
      when 'REFUNDED', 'PART_REFUNDED'
        ::MakeCommerceMessage::AppStatus::Refunded
      else
        # Including 'CANCELLED', 'EXPIRED'
        ::MakeCommerceMessage::AppStatus::Cancelled
      end
    end

    private

    def valid_notification_data?(data, mac)
      Digest::SHA512.hexdigest(data + api_secret).upcase == mac
    end

    def create_message_from_payload!
      @message = ::MakeCommerceMessage.create do |e|
        e.payment_id = payment_id
        e.app_status = status_for_notification
        e.status = gateway_status
        e.message_type = message_type
        e.amount = notification_amount
        e.currency = notification_currency

        if payment_message?
          e.customer_name = @payload[:json][:customer_name]
          e.merchant_data = @payload[:json][:merchant_data]
          e.message_time = @payload[:json][:message_time]
          e.shop = @payload[:json][:shop]
          e.reference = @payload[:json][:reference]
          e.transaction_key = @payload[:json][:transaction]
          e.signature = @payload[:json][:signature]
        end

        e.mac = @payload[:mac]
        e.raw_post = @payload[:raw_post]
      end
    end
  end
end
