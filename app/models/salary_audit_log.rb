class SalaryAuditLog < ApplicationRecord
  belongs_to :employee
  belongs_to :user
  belongs_to :salary_record, optional: true

  ACTIONS = %w[initial_creation revision correction cancellation deactivation].freeze

  validates :action, presence: true, inclusion: { in: ACTIONS }
  validates :reason, presence: true

  # Application-level immutability for the MVP: once persisted, audit logs cannot be updated or destroyed
  def readonly?
    persisted?
  end

  before_destroy { throw :abort }
end
