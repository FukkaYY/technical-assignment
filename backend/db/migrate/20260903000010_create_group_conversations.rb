class CreateGroupConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :group_conversations do |t|
      t.references :company, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.string :name, null: false, limit: 100
      t.timestamps
    end

    create_table :group_memberships do |t|
      t.references :group_conversation, null: false, foreign_key: { on_delete: :cascade }
      t.references :student, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.timestamps
      t.index %i[group_conversation_id student_id], unique: true, name: "index_group_memberships_on_group_and_student"
    end

    create_table :group_messages do |t|
      t.references :group_conversation, null: false, foreign_key: { on_delete: :cascade }
      t.references :sender, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.text :body, null: false
      t.timestamps
      t.index %i[group_conversation_id created_at id], name: "index_group_messages_on_group_and_created_at"
    end
  end
end
