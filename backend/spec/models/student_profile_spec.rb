require "rails_helper"

RSpec.describe StudentProfile, type: :model do
  it "is visible to companies by default" do
    profile = described_class.new

    expect(profile.visible_to_companies).to be(true)
  end
  def build_profile(**attributes)
    user = User.new(
      email: "student@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :student
    )

    user.build_student_profile({
      name: "山田 太郎",
      school_name: "サンプル大学",
      graduation_year: Time.zone.today.year,
      desired_role: "エンジニア",
      skills: ["Ruby"],
      self_introduction: "自己紹介"
    }.merge(attributes))
  end

  it "rejects more than 20 skills" do
    profile = build_profile(skills: 21.times.map { |index| "skill-#{index}" })

    expect(profile).not_to be_valid
    expect(profile.errors.of_kind?(:skills, :too_many)).to be(true)
  end

  it "rejects a skill longer than 50 characters" do
    profile = build_profile(skills: ["a" * 51])

    expect(profile).not_to be_valid
    expect(profile.errors.of_kind?(:skills, :too_long)).to be(true)
  end

  it "validates the limits of the separated appeal fields" do
    profile = build_profile(self_promotion: "a" * 2_001, english_skills: "a" * 1_001)

    expect(profile).not_to be_valid
    expect(profile.errors.of_kind?(:self_promotion, :too_long)).to be(true)
    expect(profile.errors.of_kind?(:english_skills, :too_long)).to be(true)
  end

  it "normalizes and validates interested roles" do
    profile = build_profile(interested_roles: [" ソフトウェアエンジニア ", "ソフトウェアエンジニア"])
    expect(profile).to be_valid
    expect(profile.interested_roles).to eq(["ソフトウェアエンジニア"])

    profile.interested_roles = ["まだ決めていない", "セールス"]
    expect(profile).not_to be_valid
    expect(profile.errors.of_kind?(:interested_roles, :invalid)).to be(true)
  end

  it "rejects a company profile association" do
    profile = build_profile
    profile.user.role = :company

    expect(profile).not_to be_valid
    expect(profile.errors.of_kind?(:user, :invalid)).to be(true)
  end
end
