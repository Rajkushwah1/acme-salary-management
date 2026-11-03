class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :role, null: false, default: "hr_manager"

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
