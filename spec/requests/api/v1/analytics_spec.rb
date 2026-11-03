require "rails_helper"

RSpec.describe "Compensation Analytics API", type: :request do
  let!(:user) do
    User.create!(
      email: "hr@acme.com",
      password: "password123",
      first_name: "Jane",
      last_name: "Doe",
      role: "hr_manager"
    )
  end

  let!(:country_us) { Country.create!(code: "US", name: "United States", default_currency: "USD") }
  let!(:country_in) { Country.create!(code: "IN", name: "India", default_currency: "INR") }
  let!(:dept_eng) { Department.create!(code: "ENG", name: "Engineering") }
  let!(:dept_sales) { Department.create!(code: "SALES", name: "Sales") }

  before do
    # US Employee 1: $120,000 annual
    e1 = Employee.create!(
      employee_code: "EMP-00001",
      first_name: "Alice",
      last_name: "US",
      email: "alice@acme.com",
      country: country_us,
      department: dept_eng,
      designation: "Senior Engineer",
      joined_at: Date.new(2023, 1, 1),
      status: "active"
    )
    e1.salary_records.create!(base_salary: 120_000, currency: "USD", pay_frequency: "annual", effective_from: Date.new(2023, 1, 1))

    # US Employee 2: $10,000 monthly -> annualized $120,000
    e2 = Employee.create!(
      employee_code: "EMP-00002",
      first_name: "Bob",
      last_name: "US",
      email: "bob@acme.com",
      country: country_us,
      department: dept_sales,
      designation: "Account Executive",
      joined_at: Date.new(2023, 1, 1),
      status: "active"
    )
    e2.salary_records.create!(base_salary: 10_000, currency: "USD", pay_frequency: "monthly", effective_from: Date.new(2023, 1, 1))

    # India Employee: ₹1,800,000 annual (Must NOT be combined into USD averages)
    e3 = Employee.create!(
      employee_code: "EMP-00003",
      first_name: "Rahul",
      last_name: "IN",
      email: "rahul@acme.com",
      country: country_in,
      department: dept_eng,
      designation: "Lead Engineer",
      joined_at: Date.new(2023, 1, 1),
      status: "active"
    )
    e3.salary_records.create!(base_salary: 1_800_000, currency: "INR", pay_frequency: "annual", effective_from: Date.new(2023, 1, 1))

    # Inactive Employee: $200,000 annual (Must NOT be included in active analytics)
    e4 = Employee.create!(
      employee_code: "EMP-00004",
      first_name: "Former",
      last_name: "Emp",
      email: "former@acme.com",
      country: country_us,
      department: dept_eng,
      designation: "Staff Engineer",
      joined_at: Date.new(2022, 1, 1),
      status: "inactive"
    )
    e4.salary_records.create!(base_salary: 200_000, currency: "USD", pay_frequency: "annual", effective_from: Date.new(2022, 1, 1), effective_to: Date.current)

    post "/api/v1/session", params: { email: "hr@acme.com", password: "password123" }
  end

  describe "GET /api/v1/analytics/summary" do
    it "returns organization counts and available currencies" do
      get "/api/v1/analytics/summary"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["total_employees"]).to eq(4)
      expect(json["active_employees"]).to eq(3)
      expect(json["inactive_employees"]).to eq(1)
      expect(json["available_currencies"]).to contain_exactly("INR", "USD")
    end
  end

  describe "GET /api/v1/analytics/breakdown" do
    it "computes annualized compensation strictly scoped to requested currency" do
      get "/api/v1/analytics/breakdown", params: { currency: "USD" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["currency"]).to eq("USD")
      expect(json["overall"]["employee_count"]).to eq(2)
      # Both e1 ($120k) and e2 ($10k monthly = $120k) annualized = $120k
      expect(json["overall"]["avg_annualized"]).to eq(120_000.0)
      expect(json["overall"]["min_annualized"]).to eq(120_000.0)
      expect(json["overall"]["max_annualized"]).to eq(120_000.0)

      # Dept breakdown
      expect(json["by_department"].length).to eq(2)
      # Country breakdown
      expect(json["by_country"].length).to eq(1)
      expect(json["by_country"].first["name"]).to eq("United States")
    end

    it "separates INR without mixing currencies" do
      get "/api/v1/analytics/breakdown", params: { currency: "INR" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["currency"]).to eq("INR")
      expect(json["overall"]["employee_count"]).to eq(1)
      expect(json["overall"]["avg_annualized"]).to eq(1_800_000.0)
    end
  end
end
