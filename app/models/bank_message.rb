class BankMessage < ActiveRecord::Base
  serialize :params
end
