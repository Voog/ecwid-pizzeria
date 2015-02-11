class EstcardMessage < ActiveRecord::Base

  def mac_input
    [
      sprintf('%03i', ver), sprintf('%-10s', merchant_id), sprintf('%012i', ecuno.to_i),
      sprintf('%06i', receipt_no.to_i), sprintf('%012i', eamount.to_i),
      cur, sprintf('%03i', respcode), datetime,
      sprintf('%-40s', msgdata), sprintf('%-40s', actiontext)
    ].join('')
  end

  def payment_id
    (ecuno.to_i / 100_000)
  end

  def valid_mac?
    mac.present? && verify_request_mac
  end

  def success?
    respcode == '000'
  end

  private

  def verify_request_mac
    if File.file?(EcwidPizzeria::Application.config.estcard.file_cert)
      public_key_file = File.read(EcwidPizzeria::Application.config.estcard.file_cert)
      certificate = OpenSSL::X509::Certificate.new(public_key_file).public_key
      certificate.verify(OpenSSL::Digest::SHA1.new, [mac].pack('H*'), mac_input)
    else
      Rails.logger.error "EstcardMessage.verify_request_mac - certificate (#{EcwidPizzeria::Application.config.estcard.file_cert}) not found!"
      false
    end
  end
end
