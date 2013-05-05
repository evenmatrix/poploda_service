class MoneyOrder < Order
  TRANSACTION_FEE = 0.015
  validates_numericality_of :amount,:greater_than_or_equal_to=>500,:less_than_or_equal_to=>100000, :only_integer => true ,:message => 'Enter a valid amount between 500 and 100000.it must be a whole number!'
  attr_accessible :item

  def name
     "Fund Wallet"
  end

  def transaction_fee
    "1.5%"
  end

  def total_amount
    self.amount+(TRANSACTION_FEE * self.amount).to_i
  end
end
