class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.references :company, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :student, null: false, foreign_key: { to_table: :users, on_delete: :cascade }

      t.timestamps
    end

    add_index :conversations, %i[company_id student_id], unique: true
    add_check_constraint :conversations, "company_id <> student_id", name: "conversations_distinct_participants"
  end
end
