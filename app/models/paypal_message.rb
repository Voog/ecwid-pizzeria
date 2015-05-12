class PaypalMessage < ActiveRecord::Base

  def self.log(request_params)
    params = {request_params: request_params}

    request_params.each do |key, value|
      column_name = key.to_s.underscore
      params[column_name] = value if column_names.include?(column_name)
    end

    self.create!(params)
  end

  def validated?
    validation_status == 'VERIFIED'
  end

  def completed?
    payment_status == 'Completed'
  end

  def pending?
    payment_status == 'Pending'
  end

  def correct_receiver?
    receiver_email == EcwidPizzeria::Application.config.paypal.login
  end

  def success?
    completed? || pending?
  end
end
