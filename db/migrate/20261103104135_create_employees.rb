class CreateEmployees < ActiveRecord::Migration[8.1]
  def up
    create_table :employees do |t|
      t.string :employee_code, limit: 16, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.references :country, null: false, foreign_key: true, index: true
      t.references :department, null: false, foreign_key: true, index: true
      t.string :designation, null: false
      t.string :status, null: false, default: "active"
      t.date :joined_at, null: false
      t.datetime :deactivated_at

      t.timestamps
    end

    add_index :employees, :employee_code, unique: true
    add_index :employees, :email, unique: true
    add_index :employees, [:status, :country_id, :department_id], name: "idx_employees_composite_filters"

    # Trigram GIN index for fast search across 10,000 employees
    execute <<-SQL
      CREATE INDEX idx_employees_trgm_search ON employees
      USING gin ((first_name || ' ' || last_name || ' ' || employee_code || ' ' || email) gin_trgm_ops);
    SQL
  end

  def down
    drop_table :employees
  end
end
