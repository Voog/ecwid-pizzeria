module PaymentsHelper

  def payment_items
    h = []
    @payment.description.split(',').each do |r|
      regexp = /(.+)\((.+)\)/
      matches = r.strip.match(regexp)
      h << {name: matches[1], amount: matches[2]}
    end
    h
  end

end
