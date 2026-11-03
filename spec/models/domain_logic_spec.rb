require "rails_helper"

RSpec.describe "Domain Models and Business Rules", type: :model do
  let!(:user) do
    User.create!(
      email: "hr@acme.com",
      password: "password123",
      first_name: "Jane",
      last_name: "Doe",
      role: "hr_manager"
    )
  end

  let!(:country) do
    Country.create!(
      code: "US",
      name: "United States",
      default_currency: "USD"
    )
  end

  let!(:department) do
    Department.create!(
      code: "ENG",
      name: "Engineering"
    )
  end

  let!(:employee) do
    Employee.create!(
      employee_code: "EMP-00001",
      first_name: "John",
      last_name: "Smith",
      email: "john.smith@acme.com",
      designation: "Software Engineer",
      country: country,
      department: department,
      joined_at: Date.new(2023, 1, 1),
      status: "active"
    )
  end

  describe "SalaryRecord constraints and integrity" do
    it "prevents overlapping salary date ranges via PostgreSQL exclusion constraint" do
      # Initial salary: 2023-01-01 to 2024-01-01
      SalaryRecord.create!(
        employee: employee,
        base_salary: 80_000,
        currency: "USD",
        pay_frequency: "annual",
        effective_from: Date.new(2023, 1, 1),
        effective_to: Date.new(2024, 1, 1)
      )

      # Attempt overlapping salary: 2023-06-01 to 2024-06-01
      expect {
        SalaryRecord.create!(
          employee: employee,
          base_salary: 90_000,
          currency: "USD",
          pay_frequency: "annual",
          effective_from: Date.new(2023, 6, 1),
          effective_to: Date.new(2024, 6, 1)
        )
      }.to raise_error(ActiveRecord::StatementInvalid, /exclude_overlapping_salaries/)
    end

    it "allows adjacent non-overlapping periods using half-open intervals [effective_from, effective_to)" do
      r1 = SalaryRecord.create!(
        employee: employee,
        base_salary: 80_000,
        currency: "USD",
        pay_frequency: "annual",
        effective_from: Date.new(2023, 1, 1),
        effective_to: Date.new(2024, 1, 1)
      )

      # Exactly touches at 2024-01-01; valid because [2023-01-01, 2024-01-01) excludes 2024-01-01
      r2 = SalaryRecord.create!(
        employee: employee,
        base_salary: 95_000,
        currency: "USD",
        pay_frequency: "annual",
        effective_from: Date.new(2024, 1, 1),
        effective_to: nil
      )

      expect(r1).to be_persisted
      expect(r2).to be_persisted
    end

    it "validates that effective_to is strictly after effective_from" do
      record = SalaryRecord.new(
        employee: employee,
        base_salary: 80_000,
        currency: "USD",
        pay_frequency: "annual",
        effective_from: Date.new(2023, 1, 1),
        effective_to: Date.new(2022, 1, 1)
      )

      expect(record).not_to be_valid
      expect(record.errors[:effective_to]).to include("must be strictly after effective from date")
    end
  end

  describe "Salary Revisions workflow" do
    before do
      employee.salary_records.create!(
        base_salary: 80_000,
        currency: "USD",
        pay_frequency: "annual",
        effective_from: Date.new(2023, 1, 1),
        effective_to: nil
      )
    end

    it "caps previous active salary and appends audit log transactionally" do
      expect {
        employee.revise_salary!(
          {
            base_salary: 95_000,
            currency: "USD",
            pay_frequency: "annual",
            effective_from: Date.new(2024, 1, 1),
            effective_to: nil
          },
          actor: user,
          reason: "Annual performance increase"
        )
      }.to change(SalaryAuditLog, :count).by(1)

      records = employee.salary_records.order(:effective_from)
      expect(records.count).to eq(2)
      expect(records.first.effective_to).to eq(Date.new(2024, 1, 1))
      expect(records.last.base_salary).to eq(95_000)

      audit = SalaryAuditLog.last
      expect(audit.action).to eq("revision")
      expect(audit.previous_salary).to eq(80_000)
      expect(audit.new_salary).to eq(95_000)
      expect(audit.user).to eq(user)
      expect(audit.reason).to eq("Annual performance increase")
    end
  end

  describe "Salary Correction workflow" do
    let!(:salary) do
      employee.salary_records.create!(
        base_salary: 80_000,
        currency: "USD",
        pay_frequency: "annual",
        effective_from: Date.new(2023, 1, 1),
        effective_to: nil
      )
    end

    it "updates record in place and records correction audit log" do
      expect {
        employee.correct_salary!(
          salary.id,
          { base_salary: 85_000 },
          actor: user,
          reason: "Clerical typo fix"
        )
      }.to change(SalaryAuditLog, :count).by(1)

      salary.reload
      expect(salary.base_salary).to eq(85_000)

      audit = SalaryAuditLog.last
      expect(audit.action).to eq("correction")
      expect(audit.previous_salary).to eq(80_000)
      expect(audit.new_salary).to eq(85_000)
      expect(audit.reason).to eq("Clerical typo fix")
    end

    it "raises error when correction reason is absent" do
      expect {
        employee.correct_salary!(
          salary.id,
          { base_salary: 85_000 },
          actor: user,
          reason: ""
        )
      }.to raise_error(ArgumentError, /Reason is mandatory/)
    end
  end

  describe "Employee Deactivation workflow" do
    let!(:current_sal) do
      employee.salary_records.create!(
        base_salary: 80_000,
        currency: "USD",
        pay_frequency: "annual",
        effective_from: Date.new(2023, 1, 1),
        effective_to: Date.today + 30.days
      )
    end

    let!(:future_sal) do
      # Scheduled future raise starting exactly when current ends
      employee.salary_records.create!(
        base_salary: 95_000,
        currency: "USD",
        pay_frequency: "annual",
        effective_from: Date.today + 30.days,
        effective_to: nil
      )
    end

    it "caps active salary, cancels future revision, and logs audits" do
      today = Date.today
      employee.deactivate!(actor: user, reason: "Employee resignation", date: today)

      employee.reload
      expect(employee.status).to eq("inactive")
      expect(employee.deactivated_at).to be_present

      current_sal.reload
      expect(current_sal.effective_to).to eq(today)

      expect {
        future_sal.reload
      }.to raise_error(ActiveRecord::RecordNotFound)

      audits = employee.salary_audit_logs.order(:created_at)
      expect(audits.map(&:action)).to include("deactivation", "cancellation")
      cancel_audit = audits.find_by(action: "cancellation")
      expect(cancel_audit.previous_salary).to eq(95_000)
      expect(cancel_audit.new_salary).to be_nil
    end
  end

  describe "SalaryAuditLog immutability" do
    let!(:audit) do
      SalaryAuditLog.create!(
        employee: employee,
        user: user,
        action: "initial_creation",
        new_salary: 80_000,
        reason: "Initial hire"
      )
    end

    it "prevents modifications at application level" do
      expect(audit.readonly?).to be true
      expect {
        audit.update(reason: "tampered reason")
      }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "prevents deletion" do
      expect {
        audit.destroy
      }.not_to change(SalaryAuditLog, :count)
    end
  end
end
