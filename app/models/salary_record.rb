class SalaryRecord < ApplicationRecord
  belongs_to :employee
  has_many :salary_audit_logs, dependent: :nullify

  PAY_FREQUENCIES = %w[annual monthly].freeze

  validates :base_salary, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true, length: { is: 3 }
  validates :pay_frequency, presence: true, inclusion: { in: PAY_FREQUENCIES }
  validates :effective_from, presence: true
  validate :effective_to_must_be_after_effective_from

  before_validation { self.currency = currency.upcase if currency.present? }

  scope :chronological, -> { order(effective_from: :asc) }
  scope :reverse_chronological, -> { order(effective_from: :desc) }

  # Resolves the active record as of a given date (defaults to today)
  scope :active_on, ->(date = Date.current) {
    where("effective_from <= :date AND (effective_to IS NULL OR effective_to > :date)", date: date)
  }

  def annualized_salary
    pay_frequency == "monthly" ? base_salary * 12 : base_salary
  end

  private

  def effective_to_must_be_after_effective_from
    return if effective_to.blank? || effective_from.blank?

    if effective_to <= effective_from
      errors.add(:effective_to, "must be strictly after effective from date")
    end
  end
end
