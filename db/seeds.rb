# db/seeds.rb
# ACME Salary Management System - Deterministic & Idempotent Seeder
# Seeds exactly 10,000 employees with associated countries, departments, and realistic salary histories.

puts "== Starting ACME Deterministic Seed Generation =="
start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

# 1. Admin / HR Manager User
admin = User.find_or_create_by!(email: "hr.manager@acme.com") do |u|
  u.first_name = "Sarah"
  u.last_name = "Connor"
  u.password = "AcmeAdmin2026!"
  u.role = "hr_manager"
end
puts "✓ Verified HR Manager: #{admin.email}"

# 2. Master Countries
countries_data = [
  { code: "US", name: "United States", default_currency: "USD" },
  { code: "IN", name: "India", default_currency: "INR" },
  { code: "GB", name: "United Kingdom", default_currency: "GBP" },
  { code: "DE", name: "Germany", default_currency: "EUR" },
  { code: "JP", name: "Japan", default_currency: "JPY" }
]

countries = countries_data.map do |c|
  Country.find_or_create_by!(code: c[:code]) do |record|
    record.name = c[:name]
    record.default_currency = c[:default_currency]
  end
end
puts "✓ Verified #{countries.count} Countries"

# 3. Master Departments
departments_data = [
  { code: "ENG", name: "Engineering" },
  { code: "PROD", name: "Product Management" },
  { code: "DES", name: "Design" },
  { code: "SALES", name: "Sales" },
  { code: "MKTG", name: "Marketing" },
  { code: "HR", name: "Human Resources" },
  { code: "FIN", name: "Finance" },
  { code: "LEGAL", name: "Legal & Compliance" }
]

departments = departments_data.map do |d|
  Department.find_or_create_by!(code: d[:code]) do |record|
    record.name = d[:name]
  end
end
puts "✓ Verified #{departments.count} Departments"

# 4. 10,000 Employees Deterministic Generator
TARGET_EMPLOYEES = 10_000
current_count = Employee.count

if current_count >= TARGET_EMPLOYEES
  puts "ℹ Found #{current_count} employees already present. Skipping creation to preserve idempotency."
else
  needed = TARGET_EMPLOYEES - current_count
  puts "Generating #{needed} employees to reach exactly #{TARGET_EMPLOYEES}..."

  first_names = %w[James Mary Robert Patricia John Jennifer Michael Linda David Elizabeth William Barbara Richard Susan Joseph Jessica Thomas Sarah Charles Karen Christopher Nancy Daniel Margaret Matthew Betty Anthony Lisa Mark Dorothy Donald Sandra Steven Ashley Paul Kimberly Andrew Donna Joshua Emily Kenneth Carol Kevin Michelle Brian Amanda George Melissa Edward Deborah Ronald Stephanie Timothy Rebecca Jason Sharon Jeffrey Laura Ryan Cynthia Jacob Kathleen Gary Amy Nicholas Shirley Eric Angela Jonathan Helen Stephen Anna Larry Brenda Justin Pamela Scott Nicole Brandon Katherine Benjamin Samantha Samuel Christine Gregory Debra Alexander Rachel Frank Carolyn Patrick Janet Raymond Maria Jack Heather Dennis Diane Jerry Virginia Tyler Julie Aaron Joyce Jose Victoria Henry Olivia Adam Kelly Nathan Christina Douglas Lauren Zachary Joan Peter Evelyn Kyle Judith Walter Megan Harold Cheryl Jeremy Andrea Ethan Hannah Christian Martha Keith Jacqueline Roger Frances Terry Ann Gerald Gloria]
  last_names = %w[Smith Johnson Williams Brown Jones Garcia Miller Davis Rodriguez Martinez Hernandez Lopez Gonzalez Wilson Anderson Thomas Taylor Moore Jackson Martin Lee Perez Thompson White Harris Sanchez Clark Ramirez Lewis Robinson Walker Young Allen King Wright Scott Torres Nguyen Hill Flores Green Adams Nelson Baker Hall Rivera Campbell Mitchell Carter Roberts Gomez Phillips Evans Turner Diaz Parker Cruz Edwards Collins Reyes Stewart Morris Morales Murphy Cook Rogers Gutierrez Ortiz Morgan Cooper Peterson Bailey Reed Kelly Howard Ramos Kim Cox Ward Richardson Watson Brooks Chavez Wood James Bennett Gray Mendoza Ruiz Hughes Price Alvarez Castillo Sanders Patel Myers Long Ross Foster]
  designations = ["Junior Associate", "Associate", "Senior Specialist", "Lead Engineer", "Staff Specialist", "Principal", "Director", "Vice President"]

  # Base salary scales per currency
  salary_scales = {
    "USD" => { min: 65_000, max: 210_000 },
    "INR" => { min: 750_000, max: 4_200_000 },
    "GBP" => { min: 45_000, max: 140_000 },
    "EUR" => { min: 50_000, max: 155_000 },
    "JPY" => { min: 5_500_000, max: 18_000_000 }
  }

  batch_size = 1000
  total_batches = (needed.to_f / batch_size).ceil
  now = Time.current

  start_index = current_count + 1
  end_index = TARGET_EMPLOYEES

  (start_index..end_index).each_slice(batch_size).with_index(1) do |slice, b_idx|
    employee_rows = []
    salary_rows = []
    audit_rows = []

    slice.each do |i|
      code = "EMP-%05d" % i
      fn = first_names[(i * 7) % first_names.length]
      ln = last_names[(i * 11) % last_names.length]
      email = "emp#{i}.#{fn.downcase}.#{ln.downcase}@acme.com"
      country = countries[i % countries.length]
      dept = departments[(i / 5) % departments.length]
      desig = designations[(i / 3) % designations.length]
      is_active = (i % 25 != 0) # 4% inactive for realistic distribution
      joined = Date.new(2020 + (i % 4), 1 + (i % 12), 1 + (i % 28))

      employee_rows << {
        employee_code: code,
        first_name: fn,
        last_name: ln,
        email: email,
        country_id: country.id,
        department_id: dept.id,
        designation: desig,
        status: is_active ? "active" : "inactive",
        joined_at: joined,
        deactivated_at: is_active ? nil : now,
        created_at: now,
        updated_at: now
      }
    end

    # Bulk insert employees
    inserted_employees = Employee.insert_all(employee_rows, returning: %i[id employee_code country_id joined_at status])

    # Build salary records and audit logs for inserted batch
    inserted_employees.each_with_index do |emp_row, idx|
      emp_id = emp_row["id"]
      country = countries.find { |c| c.id == emp_row["country_id"] }
      scale = salary_scales[country.default_currency]
      joined = emp_row["joined_at"].is_a?(Date) ? emp_row["joined_at"] : Date.parse(emp_row["joined_at"].to_s)
      is_active = emp_row["status"] == "active"

      # Base salary formula
      base_amount = scale[:min] + ((idx * 997) % (scale[:max] - scale[:min]))
      base_amount = (base_amount / 1000) * 1000 # round cleanly

      # 20% of employees have had a promotion/revision
      has_history = (idx % 5 == 0)

      if has_history
        prior_amount = (base_amount * 0.85).round(-3)
        split_date = joined + 1.year

        # Historical initial salary record
        salary_rows << {
          employee_id: emp_id,
          base_salary: prior_amount,
          currency: country.default_currency,
          pay_frequency: "annual",
          effective_from: joined,
          effective_to: split_date,
          created_at: now,
          updated_at: now
        }

        # Current active salary record
        salary_rows << {
          employee_id: emp_id,
          base_salary: base_amount,
          currency: country.default_currency,
          pay_frequency: (idx % 10 == 0) ? "monthly" : "annual",
          effective_from: split_date,
          effective_to: is_active ? nil : Date.current,
          created_at: now,
          updated_at: now
        }

        audit_rows << {
          employee_id: emp_id,
          user_id: admin.id,
          salary_record_id: nil,
          action: "revision",
          previous_salary: prior_amount,
          new_salary: base_amount,
          previous_currency: country.default_currency,
          new_currency: country.default_currency,
          previous_pay_frequency: "annual",
          new_pay_frequency: (idx % 10 == 0) ? "monthly" : "annual",
          previous_effective_from: joined,
          new_effective_from: split_date,
          previous_effective_to: split_date,
          new_effective_to: is_active ? nil : Date.current,
          reason: "Annual performance compensation increase",
          created_at: now
        }
      else
        salary_rows << {
          employee_id: emp_id,
          base_salary: base_amount,
          currency: country.default_currency,
          pay_frequency: (idx % 10 == 0) ? "monthly" : "annual",
          effective_from: joined,
          effective_to: is_active ? nil : Date.current,
          created_at: now,
          updated_at: now
        }

        audit_rows << {
          employee_id: emp_id,
          user_id: admin.id,
          salary_record_id: nil,
          action: "initial_creation",
          previous_salary: nil,
          new_salary: base_amount,
          previous_currency: nil,
          new_currency: country.default_currency,
          previous_pay_frequency: nil,
          new_pay_frequency: (idx % 10 == 0) ? "monthly" : "annual",
          previous_effective_from: nil,
          new_effective_from: joined,
          previous_effective_to: nil,
          new_effective_to: is_active ? nil : Date.current,
          reason: "Initial onboarding compensation package",
          created_at: now
        }
      end
    end

    SalaryRecord.insert_all(salary_rows)
    SalaryAuditLog.insert_all(audit_rows)
    print "."
  end
  puts "\n"
end

# 5. Verification Gate
final_count = Employee.count
raise "Seed verification failed! Expected #{TARGET_EMPLOYEES} employees, found #{final_count}" unless final_count == TARGET_EMPLOYEES

salaries_count = SalaryRecord.count
audits_count = SalaryAuditLog.count
duration = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time).round(2)

puts "=========================================================="
puts "🎉 SEED COMPLETED SUCCESSFULLY"
puts "Employees: #{final_count} (Verified exact count)"
puts "Salary Records: #{salaries_count}"
puts "Audit Logs: #{audits_count}"
puts "Total Duration: #{duration}s"
puts "=========================================================="
