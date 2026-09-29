class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: { on_delete: :cascade }
      t.references :sender, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.text :body, null: false

      t.timestamps
    end

    add_index :messages, %i[conversation_id created_at id]
  end
end
