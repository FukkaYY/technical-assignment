class StudentProfile < ApplicationRecord
  MAX_SKILLS = 20
  MAX_SKILL_LENGTH = 50
  INTERESTED_ROLE_OPTIONS = [
    "ソフトウェアエンジニア",
    "データサイエンティスト",
    "AI・機械学習エンジニア",
    "プロダクトマネージャー",
    "UI・UXデザイナー",
    "セールス",
    "マーケティング",
    "コーポレート",
    "まだ決めていない"
  ].freeze
  MAX_INTERESTED_ROLES = 3

  belongs_to :user
  belongs_to :school, optional: true
  belongs_to :faculty, optional: true
  belongs_to :department, optional: true

  scope :visible_to_companies, -> { where(visible_to_companies: true) }

  before_validation :normalize_attributes

  validates :name, presence: true, length: { maximum: 101 }
  validates :last_name, presence: true, length: { maximum: 50 }, if: :uses_education_master?
  validates :first_name, presence: true, length: { maximum: 50 }, if: :uses_education_master?
  validates :school_name, presence: true, length: { maximum: 200 }
  validates :desired_role, presence: true, length: { maximum: 100 }
  validates :self_introduction, length: { maximum: 2_000 }
  validates :self_promotion, :student_achievement, :research_summary, length: { maximum: 2_000 }
  validates :english_skills, :qualifications, length: { maximum: 1_000 }
  validates :graduation_year,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: ->(_) { Time.zone.today.year },
      less_than_or_equal_to: ->(_) { Time.zone.today.year + 2 }
    }
  validate :skills_are_valid
  validate :user_is_student
  validate :education_selection_is_consistent
  validate :interested_roles_are_valid

  def introduction_excerpt
    (self_promotion.presence || self_introduction.presence || "自己PRはまだ登録されていません。").truncate(120, omission: "…")
  end

  private

  def normalize_attributes
    self.last_name = last_name.to_s.strip.presence if last_name.present?
    self.first_name = first_name.to_s.strip.presence if first_name.present?
    self.name = [last_name, first_name].compact.join(" ") if last_name.present? || first_name.present?
    self.name = name.to_s.strip
    self.school_name = school.name if school
    self.school_name = school_name.to_s.strip
    self.desired_role = desired_role.to_s.strip
    self.interested_roles = normalize_interested_roles
    self.desired_role = interested_roles.join("、") if interested_roles.present?
    self.self_introduction = self_introduction.to_s.strip
    self.self_promotion = self_promotion.to_s.strip
    self.student_achievement = student_achievement.to_s.strip
    self.research_summary = research_summary.to_s.strip
    self.english_skills = english_skills.to_s.strip
    self.qualifications = qualifications.to_s.strip
    self.self_introduction = self_promotion if self_promotion.present?
    self.skills = normalize_skills
  end

  def uses_education_master?
    last_name.present? || first_name.present? || school_id.present?
  end

  def education_selection_is_consistent
    errors.add(:school_id, :invalid) if uses_education_master? && school.nil?
    errors.add(:faculty_id, :invalid) if faculty_id.present? && faculty.nil?
    errors.add(:department_id, :invalid) if department_id.present? && department.nil?
    if faculty && faculty.school_id != school_id
      errors.add(:faculty_id, :invalid)
    end
    if department && department.faculty_id != faculty_id
      errors.add(:department_id, :invalid)
    end
    if school && !%w[university graduate_school].include?(school.school_type) && (faculty_id.present? || department_id.present?)
      errors.add(:faculty_id, :invalid)
    end
  end

  def normalize_skills
    return skills unless skills.is_a?(Array)

    skills.filter_map do |skill|
      normalized = skill.is_a?(String) ? skill.strip : skill
      normalized unless normalized == ""
    end.uniq
  end

  def normalize_interested_roles
    return interested_roles unless interested_roles.is_a?(Array)

    interested_roles.filter_map { |role| role.is_a?(String) ? role.strip.presence : role }.uniq
  end

  def interested_roles_are_valid
    unless interested_roles.is_a?(Array)
      errors.add(:interested_roles, :invalid)
      return
    end
    errors.add(:interested_roles, :blank) if uses_education_master? && interested_roles.empty?
    errors.add(:interested_roles, :too_many, count: MAX_INTERESTED_ROLES) if interested_roles.length > MAX_INTERESTED_ROLES
    errors.add(:interested_roles, :invalid) unless interested_roles.all? { |role| INTERESTED_ROLE_OPTIONS.include?(role) }
    if interested_roles.include?("まだ決めていない") && interested_roles.length > 1
      errors.add(:interested_roles, :invalid)
    end
  end

  def skills_are_valid
    unless skills.is_a?(Array)
      errors.add(:skills, :invalid)
      return
    end

    errors.add(:skills, :too_many, count: MAX_SKILLS) if skills.length > MAX_SKILLS
    errors.add(:skills, :invalid) unless skills.all? { |skill| skill.is_a?(String) }
    errors.add(:skills, :too_long, count: MAX_SKILL_LENGTH) if skills.any? { |skill| skill.is_a?(String) && skill.length > MAX_SKILL_LENGTH }
  end

  def user_is_student
    errors.add(:user, :invalid) if user.present? && !user.student?
  end
end
