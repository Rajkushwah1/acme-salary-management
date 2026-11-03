require "rails_helper"

RSpec.describe "Salary & Audit Management API", type: :request do
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
    emp = Employee.create!(
      employee_code: "EMP-00001",
      first_name: "Alice",
      last_name: "Smith",
      email: "alice@acme.com",
      designation: "Software Engineer",
      country: country,
      department: department,
      status: "active",
      joined_at: Date.new(2023, 1, 1)
    )
    emp.salary_records.create!(
      base_salary: 80_000,
      currency: "USD",
      pay_frequency: "annual",
      effective_from: Date.new(2023, 1, 1),
      effective_to: nil
    )
    emp
  end

  before do
    post "/api/v1/session", params: { email: "hr@acme.com", password: "password123" }
  end

  describe "GET /api/v1/employees/:employee_id/salaries" do
    it "returns the employee salary timeline" do
      get "/api/v1/employees/#{employee.id}/salaries"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["salary_records"].length).to eq(1)
      expect(json["salary_records"].first["base_salary"]).to eq("80000.0")
    end
  end

  describe "POST /api/v1/employees/:employee_id/salaries/revise" do
    it "creates a new salary revision and updates previous record" do
      expect {
        post "/api/v1/employees/#{employee.id}/salaries/revise", params: {
          salary: {
            base_salary: 95_000,
            currency: "USD",
            pay_frequency: "annual",
            effective_from: "2024-01-01"
          },
          reason: "Annual performance promotion"
        }
      }.to change(SalaryRecord, :count).by(1)
       .and change(SalaryAuditLog, :count).by(1)

      expect(response).to have_http_status(:created)
      records = employee.salary_records.order(effective_from: :asc)
      expect(records.first.effective_to).to eq(Date.new(2024, 1, 1))
      expect(records.last.base_salary).to eq(95_000)

      audit = SalaryAuditLog.last
      expect(audit.action).to eq("revision")
      expect(audit.reason).to eq("Annual performance promotion")
    end
  end

  describe "PATCH /api/v1/salaries/:id/correct" do
    let(:current_salary) { employee.salary_records.first }

    it "corrects the record in place and records audit entry" do
      expect {
        patch "/api/v1/salaries/#{current_salary.id}/correct", params: {
          salary: { base_salary: 82_000 },
          reason: "Typo remediation"
        }
      }.to change(SalaryAuditLog, :count).by(1)

      expect(response).to have_http_status(:ok)
      current_salary.reload
      expect(current_salary.base_salary).to eq(82_000)

      audit = SalaryAuditLog.last
      expect(audit.action).to eq("correction")
      expect(audit.previous_salary).to eq(80_000)
      expect(audit.new_salary).to eq(82_000)
      expect(audit.reason).to eq("Typo remediation")
    end
  end

  describe "GET /api/v1/audit_logs" do
    before do
      employee.salary_audit_logs.create!(
        user: user,
        action: "initial_creation",
        new_salary: 80_000,
        reason: "Initial onboarding"
      )
    end

    it "returns paginated audit logs" do
      get "/api/v1/audit_logs"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["audit_logs"].length).to be >= 1
      expect(json["audit_logs"].first["actor"]["email"]).to eq("hr@acme.com")
      expect(json["pagination"]["total_count"]).to be >= 1
    end
  end
end
