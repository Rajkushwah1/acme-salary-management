class CreateDepartments < ActiveRecord::Migration[8.1]
  def change
    create_table :departments do |t|
      t.string :name, null: false
      t.string :code, limit: 10, null: false

      t.timestamps
    end

    add_index :departments, :name, unique: true
    add_index :departments, :code, unique: true
  end
end
