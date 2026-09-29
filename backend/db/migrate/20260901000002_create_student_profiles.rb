class CreateStudentProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :student_profiles do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.string :name, null: false, limit: 100
      t.string :school_name, null: false, limit: 200
      t.integer :graduation_year, null: false
      t.string :desired_role, null: false, limit: 100
      t.jsonb :skills, null: false, default: []
      t.text :self_introduction, null: false

      t.timestamps
    end
  end
end
