class AddStudentSeenAtToScheduleProposals < ActiveRecord::Migration[8.1]
  def change
    add_column :schedule_proposals, :student_seen_at, :datetime
  end
end
