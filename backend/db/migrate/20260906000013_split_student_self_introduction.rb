class SplitStudentSelfIntroduction < ActiveRecord::Migration[8.1]
  def up
    add_column :student_profiles, :self_promotion, :text, null: false, default: ""
    add_column :student_profiles, :student_achievement, :text, null: false, default: ""
    add_column :student_profiles, :research_summary, :text, null: false, default: ""
    add_column :student_profiles, :english_skills, :text, null: false, default: ""
    add_column :student_profiles, :qualifications, :text, null: false, default: ""

    execute <<~SQL.squish
      UPDATE student_profiles
      SET self_promotion = self_introduction
      WHERE self_introduction <> ''
    SQL
  end

  def down
    remove_columns :student_profiles,
      :self_promotion,
      :student_achievement,
      :research_summary,
      :english_skills,
      :qualifications
  end
end
