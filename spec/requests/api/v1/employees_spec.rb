require "rails_helper"

RSpec.describe "Employee Management API", type: :request do
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
      designation: "Staff Engineer",
      country: country,
      department: department,
      status: "active",
      joined_at: Date.new(2023, 1, 1)
    )
    emp.salary_records.create!(
      base_salary: 120_000,
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

  describe "GET /api/v1/employees" do
    it "lists paginated employees with current compensation" do
      get "/api/v1/employees"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["employees"].length).to eq(1)
      expect(json["employees"].first["employee_code"]).to eq("EMP-00001")
      expect(json["employees"].first["current_salary"]["base_salary"]).to eq("120000.0")
      expect(json["pagination"]["total_count"]).to eq(1)
    end

    it "filters by status" do
      get "/api/v1/employees", params: { status: "inactive" }
      json = JSON.parse(response.body)
      expect(json["employees"]).to be_empty
    end

    it "searches across names and employee codes" do
      get "/api/v1/employees", params: { search: "Alice" }
      json = JSON.parse(response.body)
      expect(json["employees"].length).to eq(1)

      get "/api/v1/employees", params: { search: "NonExistent" }
      json = JSON.parse(response.body)
      expect(json["employees"]).to be_empty
    end
  end

  describe "POST /api/v1/employees" do
    it "atomically creates employee, initial salary record, and audit log" do
      expect {
        post "/api/v1/employees", params: {
          employee: {
            employee_code: "EMP-00002",
            first_name: "Bob",
            last_name: "Jones",
            email: "bob@acme.com",
            country_id: country.id,
            department_id: department.id,
            designation: "Product Designer",
            joined_at: "2024-01-15"
          },
          salary: {
            base_salary: 95_000,
            currency: "USD",
            pay_frequency: "annual",
            effective_from: "2024-01-15"
          }
        }
      }.to change(Employee, :count).by(1)
       .and change(SalaryRecord, :count).by(1)
       .and change(SalaryAuditLog, :count).by(1)

      expect(response).to have_http_status(:created)
      new_emp = Employee.find_by(employee_code: "EMP-00002")
      expect(new_emp.salary_records.first.base_salary).to eq(95_000)
      expect(new_emp.salary_audit_logs.first.action).to eq("initial_creation")
    end
  end

  describe "POST /api/v1/employees/:id/deactivate" do
    it "deactivates the employee and caps active salary" do
      post "/api/v1/employees/#{employee.id}/deactivate", params: { reason: "Resignation" }

      expect(response).to have_http_status(:ok)
      employee.reload
      expect(employee.status).to eq("inactive")
      last_sal = employee.salary_records.order(effective_from: :desc).first
      expect(last_sal.effective_to).to eq(Date.current)
    end
  end
end
