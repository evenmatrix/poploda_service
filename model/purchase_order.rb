class PurchaseOrder < Order
  attr_accessible :item
 validates_numericality_of :amount,:message => 'Enter a valid amount'
 #validates_uniqueness_of :item_id,:scope =>:item_type

  def total_amount
    self.amount
  end

end