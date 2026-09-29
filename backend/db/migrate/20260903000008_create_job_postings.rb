class CreateJobPostings < ActiveRecord::Migration[8.1]
  def change
    create_table :job_postings do |t|
      t.references :company, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.string :title, null: false, limit: 120
      t.string :role_name, null: false, limit: 100
      t.string :work_location, null: false, limit: 200
      t.text :description, null: false
      t.text :requirements, null: false
      t.string :status, null: false, default: "published"
      t.timestamps
    end

    add_index :job_postings, %i[status created_at id]
    add_check_constraint :job_postings,
      "status IN ('published', 'closed')",
      name: "job_postings_status_check"
  end
end
