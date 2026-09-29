require "rails_helper"

RSpec.describe CompanyProfile, type: :model do
  def build_company_profile(role: :company, company_name: " デモ企業株式会社 ")
    user = User.new(
      email: "company@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: role
    )
    user.build_company_profile(company_name: company_name)
  end

  it "normalizes and accepts a company name" do
    profile = build_company_profile

    expect(profile).to be_valid
    expect(profile.company_name).to eq("デモ企業株式会社")
  end

  it "rejects a company name longer than 200 characters" do
    profile = build_company_profile(company_name: "a" * 201)

    expect(profile).not_to be_valid
    expect(profile.errors.of_kind?(:company_name, :too_long)).to be(true)
  end

  it "rejects an association with a student" do
    profile = build_company_profile(role: :student)

    expect(profile).not_to be_valid
    expect(profile.errors.of_kind?(:user, :invalid)).to be(true)
  end
end
