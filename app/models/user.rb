class User < ApplicationRecord
  has_secure_password

  has_many :salary_audit_logs, dependent: :restrict_with_error

  ROLES = %w[hr_manager admin].freeze

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, :last_name, presence: true
  validates :role, presence: true, inclusion: { in: ROLES }

  def full_name
    "#{first_name} #{last_name}".strip
  end
end
