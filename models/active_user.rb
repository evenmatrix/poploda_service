class ActiveUser < ActiveRecord::Base
  attr_accessible :jid,:phone_number
end
