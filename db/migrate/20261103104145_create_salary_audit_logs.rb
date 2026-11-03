class CreateSalaryAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :salary_audit_logs do |t|
      t.references :employee, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true
      t.references :salary_record, foreign_key: true, index: true
      t.string :action, null: false
      t.decimal :previous_salary, precision: 12, scale: 2
      t.decimal :new_salary, precision: 12, scale: 2
      t.string :previous_currency, limit: 3
      t.string :new_currency, limit: 3
      t.string :previous_pay_frequency
      t.string :new_pay_frequency
      t.date :previous_effective_from
      t.date :new_effective_from
      t.date :previous_effective_to
      t.date :new_effective_to
      t.text :reason, null: false

      t.datetime :created_at, null: false
    end

    add_index :salary_audit_logs, [:employee_id, :created_at], name: "idx_audit_logs_employee_created"
  end
end
