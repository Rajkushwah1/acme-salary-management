class Department < ApplicationRecord
  has_many :employees, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :code, presence: true, uniqueness: { case_sensitive: false }

  before_validation { self.code = code.upcase if code.present? }
end
