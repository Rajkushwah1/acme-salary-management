class Employee < ApplicationRecord
  belongs_to :country
  belongs_to :department
  has_many :salary_records, dependent: :destroy
  has_many :salary_audit_logs, dependent: :destroy

  STATUSES = %w[active inactive].freeze

  validates :employee_code, presence: true, uniqueness: { case_sensitive: false }
  validates :first_name, :last_name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :designation, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :joined_at, presence: true

  scope :active, -> { where(status: "active") }
  scope :inactive, -> { where(status: "inactive") }

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def current_salary_record(date = Date.current)
    salary_records.active_on(date).order(effective_from: :desc).first
  end

  # Revises compensation: closes currently active/future interval and creates new record transactionally
  def revise_salary!(new_attributes, actor:, reason:)
    raise ArgumentError, "Cannot revise salary for an inactive employee" if status == "inactive"
    raise ArgumentError, "Reason is mandatory" if reason.blank?

    new_from = new_attributes[:effective_from].is_a?(Date) ? new_attributes[:effective_from] : Date.parse(new_attributes[:effective_from].to_s)

    transaction do
      # 1. If there is an active record covering this start date, cap its effective_to
      active_record = current_salary_record(new_from)
      prev_salary = active_record&.base_salary
      prev_currency = active_record&.currency
      prev_freq = active_record&.pay_frequency
      prev_from = active_record&.effective_from
      prev_to = active_record&.effective_to

      if active_record && (active_record.effective_to.nil? || active_record.effective_to > new_from)
        active_record.update!(effective_to: new_from)
      end

      # 2. Create the new salary record
      new_record = salary_records.create!(
        base_salary: new_attributes[:base_salary],
        currency: new_attributes[:currency] || country.default_currency,
        pay_frequency: new_attributes[:pay_frequency] || "annual",
        effective_from: new_from,
        effective_to: new_attributes[:effective_to]
      )

      # 3. Create the immutable audit log
      salary_audit_logs.create!(
        user: actor,
        salary_record: new_record,
        action: "revision",
        previous_salary: prev_salary,
        new_salary: new_record.base_salary,
        previous_currency: prev_currency,
        new_currency: new_record.currency,
        previous_pay_frequency: prev_freq,
        new_pay_frequency: new_record.pay_frequency,
        previous_effective_from: prev_from,
        new_effective_from: new_record.effective_from,
        previous_effective_to: prev_to,
        new_effective_to: new_record.effective_to,
        reason: reason
      )

      new_record
    end
  end

  # Corrects clerical errors in an existing salary record in place transactionally
  def correct_salary!(record_id, corrected_attributes, actor:, reason:)
    raise ArgumentError, "Reason is mandatory for a correction" if reason.blank?

    transaction do
      record = salary_records.lock.find(record_id)

      prev_salary = record.base_salary
      prev_currency = record.currency
      prev_freq = record.pay_frequency
      prev_from = record.effective_from
      prev_to = record.effective_to

      record.update!(
        base_salary: corrected_attributes[:base_salary] || record.base_salary,
        currency: corrected_attributes[:currency] || record.currency,
        pay_frequency: corrected_attributes[:pay_frequency] || record.pay_frequency,
        effective_from: corrected_attributes[:effective_from] || record.effective_from,
        effective_to: corrected_attributes.key?(:effective_to) ? corrected_attributes[:effective_to] : record.effective_to
      )

      salary_audit_logs.create!(
        user: actor,
        salary_record: record,
        action: "correction",
        previous_salary: prev_salary,
        new_salary: record.base_salary,
        previous_currency: prev_currency,
        new_currency: record.currency,
        previous_pay_frequency: prev_freq,
        new_pay_frequency: record.pay_frequency,
        previous_effective_from: prev_from,
        new_effective_from: record.effective_from,
        previous_effective_to: prev_to,
        new_effective_to: record.effective_to,
        reason: reason
      )

      record
    end
  end

  # Deactivates employee: caps active salary, cancels future revisions, records audit event
  def deactivate!(actor:, reason: "Employee deactivation", date: Date.current)
    return if status == "inactive"

    transaction do
      update!(status: "inactive", deactivated_at: Time.current)

      # 1. Close active salary period at deactivation date
      active_record = current_salary_record(date)
      if active_record && (active_record.effective_to.nil? || active_record.effective_to > date)
        prev_to = active_record.effective_to
        active_record.update!(effective_to: date)

        salary_audit_logs.create!(
          user: actor,
          salary_record: active_record,
          action: "deactivation",
          previous_salary: active_record.base_salary,
          new_salary: active_record.base_salary,
          previous_currency: active_record.currency,
          new_currency: active_record.currency,
          previous_effective_to: prev_to,
          new_effective_to: date,
          reason: "#{reason}: Active salary closed on #{date}"
        )
      end

      # 2. Cancel future-dated salary revisions (preserve audit record and destroy future un-earned slice)
      future_records = salary_records.where("effective_from > ?", date)
      future_records.each do |future_rec|
        salary_audit_logs.create!(
          user: actor,
          salary_record: nil, # unlinked as record is voided
          action: "cancellation",
          previous_salary: future_rec.base_salary,
          new_salary: nil,
          previous_currency: future_rec.currency,
          previous_pay_frequency: future_rec.pay_frequency,
          previous_effective_from: future_rec.effective_from,
          previous_effective_to: future_rec.effective_to,
          reason: "#{reason}: Future revision scheduled for #{future_rec.effective_from} cancelled due to employee deactivation"
        )

        future_rec.destroy!
      end
    end
  end
end
