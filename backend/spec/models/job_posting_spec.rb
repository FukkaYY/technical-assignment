require "rails_helper"

RSpec.describe JobPosting, type: :model do
  def company
    user = User.create!(email: "company@example.com", password: "password123", password_confirmation: "password123", role: :company)
    user.create_company_profile!(company_name: "テスト企業")
    user
  end

  it "normalizes and validates posting fields" do
    posting = described_class.create!(company: company, title: "  Rails募集  ", role_name: "  エンジニア  ", work_location: "  東京・リモート  ", description: "  開発します  ", requirements: "  Ruby経験  ")

    expect(posting.attributes.slice("title", "role_name", "work_location", "description", "requirements")).to eq(
      "title" => "Rails募集", "role_name" => "エンジニア", "work_location" => "東京・リモート", "description" => "開発します", "requirements" => "Ruby経験"
    )
    expect(posting).to be_published
  end

  it "requires a company owner" do
    student = User.create!(email: "student@example.com", password: "password123", password_confirmation: "password123", role: :student)
    posting = described_class.new(company: student, title: "募集", role_name: "職種", work_location: "場所", description: "内容", requirements: "条件")

    expect(posting).not_to be_valid
    expect(posting.errors.of_kind?(:company, :invalid)).to be(true)
  end

  it "accepts only JPEG, PNG, or WebP thumbnails up to 5MB" do
    posting = described_class.new(company: company, title: "募集", role_name: "職種", work_location: "場所", description: "内容", requirements: "条件")
    posting.thumbnail.attach(io: StringIO.new("not an image"), filename: "thumbnail.txt", content_type: "text/plain")

    expect(posting).not_to be_valid
    expect(posting.errors.of_kind?(:thumbnail, :invalid)).to be(true)
  end
end
