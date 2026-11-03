# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_03_104145) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gist"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "countries", force: :cascade do |t|
    t.string "code", limit: 2, null: false
    t.string "name", null: false
    t.string "default_currency", limit: 3, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_countries_on_code", unique: true
    t.index ["name"], name: "index_countries_on_name", unique: true
  end

  create_table "departments", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", limit: 10, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_departments_on_code", unique: true
    t.index ["name"], name: "index_departments_on_name", unique: true
  end

  create_table "employees", force: :cascade do |t|
    t.string "employee_code", limit: 16, null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.bigint "country_id", null: false
    t.bigint "department_id", null: false
    t.string "designation", null: false
    t.string "status", default: "active", null: false
    t.date "joined_at", null: false
    t.datetime "deactivated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "((((((((first_name)::text || ' '::text) || (last_name)::text) || ' '::text) || (employee_code)::text) || ' '::text) || (email)::text)) gin_trgm_ops", name: "idx_employees_trgm_search", using: :gin
    t.index ["country_id"], name: "index_employees_on_country_id"
    t.index ["department_id"], name: "index_employees_on_department_id"
    t.index ["email"], name: "index_employees_on_email", unique: true
    t.index ["employee_code"], name: "index_employees_on_employee_code", unique: true
    t.index ["status", "country_id", "department_id"], name: "idx_employees_composite_filters"
  end

  create_table "salary_audit_logs", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.bigint "user_id", null: false
    t.bigint "salary_record_id"
    t.string "action", null: false
    t.decimal "previous_salary", precision: 12, scale: 2
    t.decimal "new_salary", precision: 12, scale: 2
    t.string "previous_currency", limit: 3
    t.string "new_currency", limit: 3
    t.string "previous_pay_frequency"
    t.string "new_pay_frequency"
    t.date "previous_effective_from"
    t.date "new_effective_from"
    t.date "previous_effective_to"
    t.date "new_effective_to"
    t.text "reason", null: false
    t.datetime "created_at", null: false
    t.index ["employee_id", "created_at"], name: "idx_audit_logs_employee_created"
    t.index ["employee_id"], name: "index_salary_audit_logs_on_employee_id"
    t.index ["salary_record_id"], name: "index_salary_audit_logs_on_salary_record_id"
    t.index ["user_id"], name: "index_salary_audit_logs_on_user_id"
  end

  create_table "salary_records", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.decimal "base_salary", precision: 12, scale: 2, null: false
    t.string "currency", limit: 3, null: false
    t.string "pay_frequency", default: "annual", null: false
    t.date "effective_from", null: false
    t.date "effective_to"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id", "effective_from", "effective_to"], name: "idx_salary_records_employee_dates", order: { effective_from: :desc }
    t.index ["employee_id"], name: "index_salary_records_on_employee_id"
    t.check_constraint "base_salary > 0::numeric", name: "chk_salary_positive"
    t.check_constraint "effective_to IS NULL OR effective_to > effective_from", name: "chk_salary_dates_valid"
    t.exclusion_constraint "employee_id WITH =, daterange(effective_from, COALESCE(effective_to, 'infinity'::date), '[)'::text) WITH &&", using: :gist, name: "exclude_overlapping_salaries"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "role", default: "hr_manager", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "employees", "countries"
  add_foreign_key "employees", "departments"
  add_foreign_key "salary_audit_logs", "employees"
  add_foreign_key "salary_audit_logs", "salary_records"
  add_foreign_key "salary_audit_logs", "users"
  add_foreign_key "salary_records", "employees"
end
