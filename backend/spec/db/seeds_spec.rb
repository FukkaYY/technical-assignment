require "rails_helper"

RSpec.describe "Database seeds" do
  it "creates the demo company and 25 students idempotently" do
    expect do
      2.times { load Rails.root.join("db/seeds.rb") }
    end.to change(User.company, :count).by(1)
      .and change(CompanyProfile, :count).by(1)
      .and change(JobPosting, :count).by(1)
      .and change(User.student, :count).by(25)
      .and change(StudentProfile, :count).by(25)

    company = User.find_by!(email: "company@example.com")
    expect(company.company_profile.company_name).to eq("デモ企業株式会社")
    expect(company.authenticate("password123")).to eq(company)
    expect(company.job_postings.published.pluck(:title)).to eq(["Webサービス開発インターン"])

    students = User.student.where(email: "student01@example.com".."student25@example.com")
    expect(students.count).to eq(25)
    expect(students.includes(:student_profile).all?(&:student_profile)).to be(true)
  end
end
