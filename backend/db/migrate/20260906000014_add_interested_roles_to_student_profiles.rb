class AddInterestedRolesToStudentProfiles < ActiveRecord::Migration[8.1]
  def up
    add_column :student_profiles, :interested_roles, :jsonb, null: false, default: []

    execute <<~SQL.squish
      UPDATE student_profiles
      SET interested_roles = jsonb_build_array(
        CASE
          WHEN desired_role IN ('バックエンドエンジニア', 'フロントエンドエンジニア', 'データエンジニア', 'エンジニア', '開発') THEN 'ソフトウェアエンジニア'
          WHEN desired_role = 'データサイエンティスト' THEN 'データサイエンティスト'
          WHEN desired_role IN ('AIエンジニア', '機械学習エンジニア', 'AI・機械学習エンジニア') THEN 'AI・機械学習エンジニア'
          WHEN desired_role = 'プロダクトマネージャー' THEN 'プロダクトマネージャー'
          WHEN desired_role IN ('UIデザイナー', 'UXデザイナー', 'UI・UXデザイナー') THEN 'UI・UXデザイナー'
          WHEN desired_role IN ('営業', 'セールス') THEN 'セールス'
          WHEN desired_role = 'マーケティング' THEN 'マーケティング'
          WHEN desired_role IN ('人事', '経理', '法務', 'コーポレート') THEN 'コーポレート'
          ELSE 'まだ決めていない'
        END
      )
    SQL
  end

  def down
    remove_column :student_profiles, :interested_roles
  end
end
