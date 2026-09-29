require "rails_helper"

RSpec.describe ScheduleProposal, type: :model do
  def conversation
    company = User.create!(email: "company@example.com", password: "password123", password_confirmation: "password123", role: :company)
    company.create_company_profile!(company_name: "企業")
    student = User.create!(email: "student@example.com", password: "password123", password_confirmation: "password123", role: :student)
    student.create_student_profile!(name: "学生", school_name: "大学", graduation_year: Time.zone.today.year + 1, desired_role: "エンジニア", skills: ["Ruby"], self_introduction: "自己紹介")
    Conversation.create!(company: company, student: student)
  end

  it "accepts a future proposal up to two hours" do
    start_time = 1.day.from_now
    proposal = described_class.new(conversation: conversation, starts_at: start_time, ends_at: start_time + 2.hours, location: " オンライン ", note: " 補足 ")

    expect(proposal).to be_valid
    proposal.save!
    expect(proposal.location).to eq("オンライン")
    expect(proposal.note).to eq("補足")
    expect(proposal).to be_pending
  end

  it "rejects past, reversed, and over-two-hour periods" do
    past = described_class.new(conversation: conversation, starts_at: 1.hour.ago, ends_at: 1.hour.from_now, location: "オンライン")
    expect(past).not_to be_valid
    expect(past.errors.of_kind?(:starts_at, :future)).to be(true)

    start_time = 1.day.from_now
    too_long = described_class.new(conversation: past.conversation, starts_at: start_time, ends_at: start_time + 3.hours, location: "オンライン")
    expect(too_long).not_to be_valid
    expect(too_long.errors.of_kind?(:ends_at, :duration)).to be(true)
  end

  it "allows only one transition from pending" do
    proposal = described_class.create!(conversation: conversation, starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour, location: "オンライン")
    proposal.transition_from_pending!(:accepted)

    expect { proposal.transition_from_pending!(:declined) }.to raise_error(ActiveRecord::RecordInvalid)
    expect(proposal.reload).to be_accepted
  end
end
