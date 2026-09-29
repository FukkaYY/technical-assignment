class CreateScheduleProposals < ActiveRecord::Migration[8.1]
  def change
    create_table :schedule_proposals do |t|
      t.references :conversation, null: false, foreign_key: { on_delete: :cascade }
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :location, null: false, limit: 200
      t.text :note, null: false, default: ""
      t.string :status, null: false, default: "pending"
      t.timestamps
    end

    add_index :schedule_proposals, %i[conversation_id created_at id], name: "index_schedule_proposals_on_conversation_and_created_at"
    add_check_constraint :schedule_proposals,
      "status IN ('pending', 'accepted', 'declined', 'cancelled')",
      name: "schedule_proposals_status_check"
    add_check_constraint :schedule_proposals, "ends_at > starts_at", name: "schedule_proposals_valid_period"
  end
end
