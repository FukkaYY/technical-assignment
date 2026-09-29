require "rails_helper"

RSpec.describe "Schedule proposals", type: :request do
  before { Rails.cache.clear }

  let!(:company) { create_user("company@example.com", :company) }
  let!(:other_company) { create_user("other-company@example.com", :company) }
  let!(:student) { create_user("student@example.com", :student) }
  let!(:other_student) { create_user("other-student@example.com", :student) }
  let!(:conversation) { Conversation.create!(company: company, student: student) }
  let(:starts_at) { 2.days.from_now.in_time_zone("Asia/Tokyo").change(min: 30, sec: 0).strftime("%Y-%m-%dT%H:%M") }
  let(:attributes) { { starts_at: starts_at, duration_minutes: 60, location: "オンライン", note: "履歴書をご用意ください" } }

  def create_user(email, role)
    user = User.create!(email: email, password: "password123", password_confirmation: "password123", role: role)
    if role == :company
      user.create_company_profile!(company_name: "テスト企業")
    else
      user.create_student_profile!(name: email, school_name: "大学", graduation_year: Time.zone.today.year + 1, desired_role: "エンジニア", skills: ["Ruby"], self_introduction: "自己紹介")
    end
    user
  end

  def csrf_token
    get "/api/v1/csrf"
    response.parsed_body.dig("data", "csrf_token")
  end

  def login_as(user)
    post "/api/v1/session", params: { session: { email: user.email, password: "password123", role: user.role } }, headers: { "X-CSRF-Token" => csrf_token }, as: :json
    expect(response).to have_http_status(:ok)
  end

  def create_proposal
    conversation.schedule_proposals.create!(starts_at: 2.days.from_now, ends_at: 2.days.from_now + 1.hour, location: "オンライン", note: "補足")
  end

  it "lets the company propose a Japan-time schedule on an existing conversation" do
    login_as(company)

    expect {
      post "/api/v1/students/#{student.id}/schedule_proposals", params: { schedule_proposal: attributes }, headers: { "X-CSRF-Token" => csrf_token }, as: :json
    }.to change(ScheduleProposal, :count).by(1)

    expect(response).to have_http_status(:created)
    proposal = ScheduleProposal.last
    expected = ActiveSupport::TimeZone["Asia/Tokyo"].strptime(starts_at, "%Y-%m-%dT%H:%M")
    expect(proposal.starts_at).to eq(expected)
    expect(proposal.ends_at).to eq(expected + 60.minutes)
    expect(proposal.conversation).to eq(conversation)
  end

  it "requires an existing conversation and valid future period" do
    login_as(company)
    post "/api/v1/students/#{other_student.id}/schedule_proposals", params: { schedule_proposal: attributes }, headers: { "X-CSRF-Token" => csrf_token }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("errors", 0, "field")).to eq("conversation")

    [{ starts_at: starts_at.sub(/:30\z/, ":31") }, { duration_minutes: 10 }, { duration_minutes: 135 }].each do |invalid|
      post "/api/v1/students/#{student.id}/schedule_proposals", params: { schedule_proposal: attributes.merge(invalid) }, headers: { "X-CSRF-Token" => csrf_token }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  it "lets only the recipient student accept a pending proposal" do
    proposal = create_proposal
    login_as(student)
    patch "/api/v1/schedule_proposals/#{proposal.id}/accept", headers: { "X-CSRF-Token" => csrf_token }, as: :json
    expect(response).to have_http_status(:ok)
    expect(proposal.reload).to be_accepted
    expect(proposal.student_seen_at).to be_present

    patch "/api/v1/schedule_proposals/#{proposal.id}/decline", headers: { "X-CSRF-Token" => csrf_token }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(proposal.reload).to be_accepted
  end

  it "lets only the proposing company cancel a pending proposal" do
    proposal = create_proposal
    login_as(other_company)
    patch "/api/v1/company/schedule_proposals/#{proposal.id}/cancel", headers: { "X-CSRF-Token" => csrf_token }, as: :json
    expect(response).to have_http_status(:not_found)

    delete "/api/v1/session", headers: { "X-CSRF-Token" => csrf_token }
    login_as(company)
    patch "/api/v1/company/schedule_proposals/#{proposal.id}/cancel", headers: { "X-CSRF-Token" => csrf_token }, as: :json
    expect(response).to have_http_status(:ok)
    expect(proposal.reload).to be_cancelled
  end

  it "hides another student's proposal" do
    proposal = create_proposal
    login_as(other_student)
    patch "/api/v1/schedule_proposals/#{proposal.id}/accept", headers: { "X-CSRF-Token" => csrf_token }, as: :json
    expect(response).to have_http_status(:not_found)
    expect(proposal.reload).to be_pending
  end

  it "includes proposals in both conversation histories" do
    proposal = create_proposal
    login_as(company)
    get "/api/v1/students/#{student.id}/messages"
    expect(response.parsed_body.dig("data", "schedule_proposals", 0, "id")).to eq(proposal.id)

    delete "/api/v1/session", headers: { "X-CSRF-Token" => csrf_token }
    login_as(student)
    get "/api/v1/conversations/#{conversation.id}"
    expect(response.parsed_body.dig("data", "schedule_proposals", 0, "id")).to eq(proposal.id)
  end

  it "requires CSRF protection for schedule changes" do
    login_as(company)
    post "/api/v1/students/#{student.id}/schedule_proposals", params: { schedule_proposal: attributes }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(ScheduleProposal.count).to eq(0)
  end
end
