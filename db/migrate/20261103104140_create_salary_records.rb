class CreateSalaryRecords < ActiveRecord::Migration[8.1]
  def up
    create_table :salary_records do |t|
      t.references :employee, null: false, foreign_key: true, index: true
      t.decimal :base_salary, precision: 12, scale: 2, null: false
      t.string :currency, limit: 3, null: false
      t.string :pay_frequency, null: false, default: "annual"
      t.date :effective_from, null: false
      t.date :effective_to

      t.timestamps
    end

    add_check_constraint :salary_records, "base_salary > 0", name: "chk_salary_positive"
    add_check_constraint :salary_records, "effective_to IS NULL OR effective_to > effective_from", name: "chk_salary_dates_valid"

    add_index :salary_records, [:employee_id, :effective_from, :effective_to], order: { effective_from: :desc }, name: "idx_salary_records_employee_dates"

    # PostgreSQL exclusion constraint to prevent overlapping salary periods
    execute <<-SQL
      ALTER TABLE salary_records
      ADD CONSTRAINT exclude_overlapping_salaries
      EXCLUDE USING gist (
        employee_id WITH =,
        daterange(effective_from, COALESCE(effective_to, 'infinity'::date), '[)') WITH &&
      );
    SQL
  end

  def down
    drop_table :salary_records
  end
end
