class EstcardRequest < ActiveRecord::Base

  attr_accessor :mac

  def mac_input
    [ver, sprintf('%-10s', merchant_id), sprintf('%012i', ecuno), sprintf('%012i', eamount), cur, datetime].join('')
  end
end
