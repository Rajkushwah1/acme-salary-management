class Country < ApplicationRecord
  has_many :employees, dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: { case_sensitive: false }, length: { is: 2 }
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :default_currency, presence: true, length: { is: 3 }

  before_validation { self.code = code.upcase if code.present? }
  before_validation { self.default_currency = default_currency.upcase if default_currency.present? }
end
