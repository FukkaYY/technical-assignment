company_email = if Rails.env.production?
  ENV.fetch("DEMO_COMPANY_EMAIL")
else
  ENV.fetch("DEMO_COMPANY_EMAIL", "company@example.com")
end

company_password = if Rails.env.production?
  ENV.fetch("DEMO_COMPANY_PASSWORD")
else
  ENV.fetch("DEMO_COMPANY_PASSWORD", "password123")
end

normalized_email = company_email.strip.downcase

User.transaction do
  company = User.find_or_initialize_by(email: normalized_email)
  if company.persisted? && !company.company?
    raise "Seed email is already assigned to a non-company user"
  end

  company.assign_attributes(
    role: :company,
    password: company_password,
    password_confirmation: company_password
  )
  company.save!

  profile = company.company_profile || company.build_company_profile
  profile.company_name = "デモ企業株式会社"
  profile.save!

  posting = company.job_postings.find_or_initialize_by(title: "Webサービス開発インターン")
  posting.assign_attributes(
    role_name: "バックエンドエンジニア",
    work_location: "東京都・週2日リモート可",
    description: "RailsとNext.jsを使ったWebサービスの企画・開発に参加します。",
    requirements: "Web開発への関心があり、Gitを使った開発を学んでいること。",
    status: :published
  )
  posting.save!
end

education_seed = {
  "technical_college" => { "東京デモ高専" => {} },
  "vocational_school" => { "デモ情報専門学校" => {} },
  "junior_college" => { "サンプル短期大学" => {} },
  "university" => {
    "東京デモ大学" => { "工学部" => ["情報工学科", "機械工学科"], "経済学部" => ["経済学科"] },
    "関西サンプル大学" => { "情報学部" => ["情報システム学科", "データ科学科"] },
    "北海道テスト大学" => { "理学部" => ["数学科", "物理学科"] },
    "九州モック工科大学" => { "工学部" => ["情報通信工学科"] }
  },
  "graduate_school" => {
    "東京デモ大学大学院" => { "工学研究科" => ["情報工学専攻", "機械工学専攻"] },
    "関西サンプル大学大学院" => { "情報学研究科" => ["情報システム専攻"] }
  }
}

education_seed.each do |school_type, schools|
  schools.each do |school_name, faculties|
    school = School.find_or_create_by!(school_type: school_type, name: school_name)
    faculties.each do |faculty_name, departments|
      faculty = school.faculties.find_or_create_by!(name: faculty_name)
      departments.each { |department_name| faculty.departments.find_or_create_by!(name: department_name) }
    end
  end
end

student_schools = School.where(school_type: "university").order(:id).to_a
interested_role_sets = [
  ["ソフトウェアエンジニア"],
  ["ソフトウェアエンジニア", "UI・UXデザイナー"],
  ["データサイエンティスト", "AI・機械学習エンジニア"],
  ["プロダクトマネージャー"]
]
skill_sets = [
  ["Ruby", "Rails", "PostgreSQL", "Docker"],
  ["TypeScript", "React", "Next.js"],
  ["Python", "SQL", "AWS", "Git"],
  ["Figma", "TypeScript"]
]

25.times do |index|
  number = index + 1
  email = format("student%02d@example.com", number)

  User.transaction do
    student = User.find_or_initialize_by(email: email)
    if student.persisted? && !student.student?
      raise "Seed email is already assigned to a non-student user: #{email}"
    end

    student.assign_attributes(
      role: :student,
      password: "password123",
      password_confirmation: "password123"
    )
    student.save!

    profile = student.student_profile || student.build_student_profile
    school = student_schools[index % student_schools.length]
    faculty = school.faculties.first
    profile.assign_attributes(
      last_name: "デモ学生",
      first_name: format("%02d", number),
      school: school,
      faculty: faculty,
      department: faculty&.departments&.first,
      graduation_year: Time.zone.today.year + ((index + 1) % 3),
      interested_roles: interested_role_sets[index % interested_role_sets.length],
      skills: skill_sets[index % skill_sets.length],
      self_promotion: "架空のデモ学生#{number}です。学業と個人開発を両立し、チームで価値を届けることに関心があります。"
    )
    profile.save!
  end
end
