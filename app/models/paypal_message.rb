class PaypalMessage < ActiveRecord::Base
  PDT_TO_IPN = {
    'amt' => 'mc_gross',
    'cc' => 'mc_currency',
    'cm' => 'transaction_subject',
    'st' => 'payment_status',
    'tx' => 'txn_id'
  }

  def self.log(request_params)
    params = {request_params: request_params}

    # Process IPN request
    request_params.each do |key, value|
      column_name = PDT_TO_IPN.fetch(key.to_s, key).to_s.underscore
      params[column_name] = value if column_names.include?(column_name)
    end

    # There has no date in PDT request
    params[:payment_date] = Time.now if params[:payment_date].blank? && request_params.key?(:tx)

    self.create!(params)
  end

  # IPN (automatic) or PDT (user initailized return) message
  def ipn_message?
    invoice.present?
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
