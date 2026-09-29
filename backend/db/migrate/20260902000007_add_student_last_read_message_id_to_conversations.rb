class AddStudentLastReadMessageIdToConversations < ActiveRecord::Migration[8.1]
  def change
    add_column :conversations, :student_last_read_message_id, :bigint
    add_index :conversations, :student_last_read_message_id
    add_check_constraint :conversations,
      "student_last_read_message_id IS NULL OR student_last_read_message_id > 0",
      name: "conversations_student_last_read_message_id_positive"
  end
end
