class AddVisibleToCompaniesToStudentProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :student_profiles, :visible_to_companies, :boolean, null: false, default: true
    remove_index :student_profiles, name: "index_student_profiles_on_created_at_and_id"
    add_index :student_profiles, %i[visible_to_companies created_at id], name: "index_student_profiles_on_visibility_and_list_order"
  end
end
