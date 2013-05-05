class Airtime < ActiveRecord::Base
  MTN_ALERT = 50
  GLO_ALERT = 50
  AIRTEL_ALERT = 50
  ETISALAT_ALERT = 50

  attr_accessible :price, :pin, :card_type
  validates_inclusion_of :price, in: [100, 200, 400, 750, 1500, 3000], if: :mtn
  validates_inclusion_of :price, in: [100, 500, 1000], if: :glo
  validates_inclusion_of :price, in: [100, 500, 1000], if: :airtel
  validates_inclusion_of :price, in: [100, 500, 1000], if: :etisalat
  validates_inclusion_of :card_type, in: %w(mtn glo etisalat airtel)
  validates_numericality_of :pin
  validates :price, :pin, :card_type, :presence => true
  validates_length_of :pin, is: 12, :message => 'Invalid Recharge Card', if: :mtn
  validates_length_of :pin, is: 15, :message => 'Invalid Recharge Card', if: :glo
  validates_length_of :pin, is: 12, :message => 'Invalid Recharge Card', if: :airtel
  validates_length_of :pin, is: 16, :message => 'Invalid Recharge Card', if: :etisalat
  validates_presence_of :encrypted_pin, :message => "Pls input a recharge card"
  validates_uniqueness_of :encrypted_pin, :message => "already added in the database"
  before_save :set_price
  has_one :order, :as=>:item

  scope :not_sold, lambda { |card_name| where("name = (?)", card_name).order("RANDOM()")}
  scope :available_credits_count, lambda { |card_name| where("name = (?)", card_name)}
  scope :fetch_cards, lambda { |card_name| where("card_type = (?)", card_name)}
  scope :open_credits, -> {with_state(:open)}
  scope :sold, -> {with_state(:sold)}
  scope :pending, -> {with_state(:awaiting_payment)}

  scope :mtn_credit, lambda  { where("card_type = ? AND sold = ?", "mtn", false)}
  scope :glo_credit, lambda  { where("card_type = ? AND sold = ?", "glo", false)}
  scope :etisalat_credit, lambda  { where("card_type = ? AND sold = ?", "etisalat", false)}
  scope :airtel_credit, lambda  { where("card_type = ? AND sold = ?", "airtel", false)}

  scope :today, where("date(created_at) = ?", Date.today)


  state_machine initial: :open do
    after_transition :awaiting_payment => :sold, :do => :notify

    event :assigned_to_order do
      transition :open => :awaiting_payment
    end

    event :payment_complete do
      transition :awaiting_payment => :sold
    end

    event :canceled do
      transition :awaiting_payment => :open
    end
  end

  attr_encrypted :pin, :key => '&@it)a|S_eouL-hnBq^BJ_!]&A+3pTaw9|N;,kYMD(s.*/UmQD8F|-`HC<#<Qm'

  def on_order_success(order)
    self.payment_complete
  end

  def on_order_failed(order)
     self.canceled
  end

  def on_order_canceled(order)
    self.canceled
  end

  def order_title
      "Recharge Card Pin Purchase"
  end

  def order_type
      "Airtime"
  end

  def open?
    self.state == "open"
  end

  def notify
    CreditNotice.credit_notice(self.order.user,self.pin).deliver
  end

  def set_price
    #self.price = self.amount
    self.name = [self.card_type.downcase, self.price].compact.join("_")
    self.encrypted_pin
  end

  def mtn
    self.card_type == "mtn"
  end

  def glo
    self.card_type == "glo"
  end

  def airtel
    self.card_type == "airtel"
  end

  def etisalat
    self.card_type == "etisalat"
  end

  def self.total_amount
    sum(&:price)
  end

  def self.total_amount_available
    sum(&:price) - sold.sum(&:price)
  end

  def self.total_added_today
     amount_today = today.sum(&:price)
     total_sold = sold.total_amount
     CreditNotice.credit_amount_notice(amount_today, total_sold).deliver
  end


  def self.low_mtn_100
    CreditNotice.low_credit("MTN 100").deliver if available_credits_count("mtn_100").open_credits.count <= MTN_ALERT
  end

  def self.low_mtn_200
    CreditNotice.low_credit("MTN 200").deliver if available_credits_count("mtn_200").open_credits.count <= MTN_ALERT
  end

  def self.low_mtn_400
    CreditNotice.low_credit("MTN 400").deliver if available_credits_count("mtn_400").open_credits.count <= MTN_ALERT
  end

  def self.low_mtn_1500
    CreditNotice.low_credit("MTN 1500").deliver if available_credits_count("mtn_1500").open_credits.count <= MTN_ALERT
  end

  def self.low_mtn_3000
    CreditNotice.low_credit("MTN 3000").deliver if available_credits_count("mtn_3000").open_credits.count <= MTN_ALERT
  end

  def self.low_glo_100
    CreditNotice.low_credit("GLO 100").deliver if available_credits_count("glo_100").open_credits.count <= GLO_ALERT
  end

  def self.low_glo_500
    CreditNotice.low_credit("GLO 500").deliver if available_credits_count("glo_500").open_credits.count <= GLO_ALERT
  end

  def self.low_glo_1000
    CreditNotice.low_credit("GLO 1000").deliver if available_credits_count("glo_1000").open_credits.count <= GLO_ALERT
  end

  def self.low_airtel_100
    CreditNotice.low_credit("AIRTEL 100").deliver if available_credits_count("airtel_100").open_credits.count <= AIRTEL_ALERT
  end

  def self.low_airtel_500
    CreditNotice.low_credit("AIRTEL 500").deliver if available_credits_count("airtel_500").open_credits.count <= AIRTEL_ALERT
  end

  def self.low_airtel_1000
    CreditNotice.low_credit("AIRTEL 1000").deliver if available_credits_count("airtel_1000").open_credits.count <= AIRTEL_ALERT
  end

  def self.low_etisalat_100
    CreditNotice.low_credit("ETISALAT 100").deliver if available_credits_count("etisalat_100").open_credits.count <= AIRTEL_ALERT
  end

  def self.low_etisalat_500
    CreditNotice.low_credit("ETISALAT 500").deliver if available_credits_count("etisalat_500").open_credits.count <= AIRTEL_ALERT
  end

  def self.low_etisalat_1000
    CreditNotice.low_credit("ETISALAT 1000").deliver if available_credits_count("etisalat_1000").open_credits.count <= AIRTEL_ALERT
  end


  def self.import(file)
    spreadsheet = open_spreadsheet(file)
    header = spreadsheet.row(1)
    (2..spreadsheet.last_row).each do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      credit = find_by_id(row["id"]) || new
      credit.attributes = row.to_hash.slice(*accessible_attributes)
      credit.save!
    end
  end

  def self.open_spreadsheet(file)
    case File.extname(file.original_filename)
      when ".csv" then Csv.new(file.path, nil, :ignore)
      when ".xls" then Excel.new(file.path, nil, :ignore)
      when ".xlsx" then Excelx.new(file.path, nil, :ignore)
      else raise "Unknown file type: #{file.original_filename}"
    end
  end

  def one_click
    if card_type == "mtn"
     ["*555*", pin, "#"].compact.join("")
    elsif card_type == "glo"
      ["*123*", pin, "#"].compact.join("")
    elsif card_type == "airtel"
      ["*126*", pin, "#"].compact.join("")
    elsif card_type == "etisalat"
      ["*555*", pin, "#"].compact.join("")
    else
        pin
    end

  end



end