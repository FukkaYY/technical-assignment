class AddListOrderIndexToStudentProfiles < ActiveRecord::Migration[8.1]
  def change
    add_index :student_profiles, %i[created_at id], name: "index_student_profiles_on_created_at_and_id"
  end
end
