class CreateTeachers < ActiveRecord::Migration[5.2]
  def change
    create_table :teachers do |t|
      t.string :email

      t.timestamps
    end
    add_index :teachers, :email, unique: true
  end
end
