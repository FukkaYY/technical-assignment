class AddEducationMastersAndSplitStudentNames < ActiveRecord::Migration[8.1]
  def change
    create_table :schools do |t|
      t.string :name, null: false, limit: 200
      t.string :school_type, null: false, limit: 30
      t.timestamps
    end
    add_index :schools, [:school_type, :name], unique: true

    create_table :faculties do |t|
      t.references :school, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false, limit: 200
      t.timestamps
    end
    add_index :faculties, [:school_id, :name], unique: true

    create_table :departments do |t|
      t.references :faculty, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false, limit: 200
      t.timestamps
    end
    add_index :departments, [:faculty_id, :name], unique: true

    add_column :student_profiles, :last_name, :string, limit: 50
    add_column :student_profiles, :first_name, :string, limit: 50
    reversible do |direction|
      direction.up { change_column :student_profiles, :name, :string, limit: 101, null: false }
      direction.down { change_column :student_profiles, :name, :string, limit: 100, null: false }
    end
    add_reference :student_profiles, :school, foreign_key: { on_delete: :restrict }
    add_reference :student_profiles, :faculty, foreign_key: { on_delete: :restrict }
    add_reference :student_profiles, :department, foreign_key: { on_delete: :restrict }
  end
end
