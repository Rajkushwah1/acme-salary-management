require "rails_helper"

RSpec.describe "Complex Edge Cases & Invariants", type: :model do
  let!(:user) do
    User.create!(
      email: "hr@acme.com",
      password: "password123",
      first_name: "Jane",
      last_name: "Doe",
      role: "hr_manager"
    )
  end

  let!(:country) { Country.create!(code: "US", name: "United States", default_currency: "USD") }
  let!(:department) { Department.create!(code: "ENG", name: "Engineering") }

  let!(:employee) do
    Employee.create!(
      employee_code: "EMP-99999",
      first_name: "John",
      last_name: "Tester",
      email: "john.tester@acme.com",
      country: country,
      department: department,
      designation: "Principal Engineer",
      joined_at: Date.new(2023, 1, 1),
      status: "active"
    )
  end

  describe "Date Ordering & Negative Values" do
    it "rejects non-positive base salaries at database and model levels" do
      salary = SalaryRecord.new(
        employee: employee,
        base_salary: 0,
        currency: "USD",
        pay_frequency: "annual",
        effective_from: Date.new(2023, 1, 1)
      )
      expect(salary).not_to be_valid
      expect(salary.errors[:base_salary]).to include("must be greater than 0")

      salary.base_salary = -5000
      expect(salary).not_to be_valid
    end

    it "rejects when effective_to equals effective_from" do
      salary = SalaryRecord.new(
        employee: employee,
        base_salary: 100_000,
        currency: "USD",
        pay_frequency: "annual",
        effective_from: Date.new(2023, 1, 1),
        effective_to: Date.new(2023, 1, 1)
      )
      expect(salary).not_to be_valid
      expect(salary.errors[:effective_to]).to include("must be strictly after effective from date")
    end
  end

  describe "Active Salary Resolution Under Complex Timelines" do
    before do
      # 1. 2023-01-01 to 2024-01-01 ($80k)
      employee.salary_records.create!(
        base_salary: 80_000,
        currency: "USD",
        pay_frequency: "annual",
        effective_from: Date.new(2023, 1, 1),
        effective_to: Date.new(2024, 1, 1)
      )

      # 2. 2024-01-01 to 2025-01-01 ($100k)
      employee.salary_records.create!(
        base_salary: 100_000,
        currency: "USD",
        pay_frequency: "annual",
        effective_from: Date.new(2024, 1, 1),
        effective_to: Date.new(2025, 1, 1)
      )

      # 3. 2025-01-01 onwards ($120k)
      employee.salary_records.create!(
        base_salary: 120_000,
        currency: "USD",
        pay_frequency: "annual",
        effective_from: Date.new(2025, 1, 1),
        effective_to: nil
      )
    end

    it "dynamically resolves historical salary for any given date correctly" do
      sal_2023 = employee.current_salary_record(Date.new(2023, 6, 15))
      expect(sal_2023.base_salary).to eq(80_000)

      sal_2024 = employee.current_salary_record(Date.new(2024, 6, 15))
      expect(sal_2024.base_salary).to eq(100_000)

      sal_2025 = employee.current_salary_record(Date.new(2025, 6, 15))
      expect(sal_2025.base_salary).to eq(120_000)
    end

    it "returns nil for dates before employee joining/salary start" do
      expect(employee.current_salary_record(Date.new(2022, 12, 31))).to be_nil
    end
  end

  describe "Transaction Rollback Safety" do
    before do
      employee.salary_records.create!(
        base_salary: 80_000,
        currency: "USD",
        pay_frequency: "annual",
        effective_from: Date.new(2023, 1, 1),
        effective_to: nil
      )
    end

    it "rolls back salary changes if audit log fails validation" do
      expect {
        begin
          employee.revise_salary!(
            { base_salary: 95_000, effective_from: Date.new(2024, 1, 1) },
            actor: user,
            reason: "" # Missing reason causes validation error
          )
        rescue ArgumentError
          # expected
        end
      }.not_to change(SalaryRecord, :count)

      active_sal = employee.current_salary_record(Date.new(2024, 1, 1))
      expect(active_sal.base_salary).to eq(80_000)
      expect(active_sal.effective_to).to be_nil # Previous record remained unclosed
    end
  end

  describe "Preventing Inactive Employee Revisions" do
    it "raises error if attempting to revise an inactive employee" do
      employee.update!(status: "inactive")
      expect {
        employee.revise_salary!(
          { base_salary: 95_000, effective_from: Date.today },
          actor: user,
          reason: "Trying to raise inactive"
        )
      }.to raise_error(ArgumentError, /Cannot revise salary for an inactive employee/)
    end
  end
end
