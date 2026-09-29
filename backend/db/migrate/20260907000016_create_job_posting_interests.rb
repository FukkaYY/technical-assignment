class CreateJobPostingInterests < ActiveRecord::Migration[8.1]
  def change
    create_table :job_posting_interests do |t|
      t.references :student, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :job_posting, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end

    add_index :job_posting_interests, %i[student_id job_posting_id], unique: true
  end
end
