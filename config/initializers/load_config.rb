require 'yaml'
require 'ostruct'

class NestedOpenStruct < OpenStruct
  def initialize(hash = nil)
    @table = {}
    if hash
      for k, v in hash
        # handle nested hashes
        if v.is_a? Hash
          @table[k.to_sym] = NestedOpenStruct.new(v)
          
        # handle nested hashes nested in arrays
        elsif v.is_a? Array
          if v.all? {|entry| entry.is_a? Hash }
            @table[k.to_sym] = v.map {|v| NestedOpenStruct.new(v) }
          end
          
        else
          @table[k.to_sym] = v
          new_ostruct_member(k)
        end
      end
    end
  end
end

module EcwidPizzeria
  class << self
    attr_accessor :config
  end
end

EcwidPizzeria.config = NestedOpenStruct.new(YAML.load_file(Rails.root.join('config/config.yml'))[Rails.env])

if EcwidPizzeria.config.mailer.delivery_method == 'smtp'
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = EcwidPizzeria.config.mailer.smtp_settings.marshal_dump
end
