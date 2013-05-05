class Payment < ActiveRecord::Base
  belongs_to :order
  # attr_accessible :title, :body
end
