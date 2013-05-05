class CreditImport
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :file, :pin

  def initialize(attributes = {})
    attributes.each { |name, value| send("#{name}=", value) }
  end

  def persisted?
    false
  end

  def save
    if imported_credits.map(&:valid?).all?
      imported_credits.each(&:save!)
      true
    else
      imported_credits.each_with_index do |product, index|
        product.errors.full_messages.each do |message|
          errors.add :base, "Row #{index+2}: #{message}"
        end
      end
      false
    end
  end

  def imported_credits
    @imported_credits ||= load_imported_credit
  end

  def load_imported_credit
    spreadsheet = open_spreadsheet
    header = spreadsheet.row(1)
    (2..spreadsheet.last_row).map do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      credit = Airtime.find_by_id(row["id"]) || Airtime.new
      credit.attributes = row.to_hash.slice(*Airtime.accessible_attributes)
      credit
    end
  end

  def open_spreadsheet
    case File.extname(file.original_filename)
      when ".csv" then Roo::Csv.new(file.path, nil, :ignore)
      when ".xls" then Roo::Excel.new(file.path, nil, :ignore)
      when ".xlsx" then Roo::Excelx.new(file.path, nil, :ignore)
      else raise "Unknown file type: #{file.original_filename}"
    end
  end
end
