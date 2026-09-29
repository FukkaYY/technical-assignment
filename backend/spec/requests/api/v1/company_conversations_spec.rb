require "rails_helper"

RSpec.describe "Company conversations", type: :request do
  before { Rails.cache.clear }

  let!(:company) { create_company("company@example.com", "自社") }
  let!(:other_company) { create_company("other@example.com", "他社") }
  let!(:first_student) { create_student("first@example.com", "学生 一郎") }
  let!(:second_student) { create_student("second@example.com", "学生 二郎") }

  def create_company(email, name)
    user = User.create!(email: email, password: "password123", password_confirmation: "password123", role: :company)
    user.create_company_profile!(company_name: name)
    user
  end

  def create_student(email, name)
    user = User.create!(email: email, password: "password123", password_confirmation: "password123", role: :student)
    user.create_student_profile!(name: name, school_name: "大学", graduation_year: Time.zone.today.year + 1, desired_role: "エンジニア", skills: ["Ruby"], self_introduction: "自己紹介")
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

  it "returns only the company's conversations with newest activity first" do
    older = Conversation.create!(company: company, student: first_student)
    older_message = older.messages.create!(sender: company, body: "以前の送信")
    older_message.update_columns(created_at: 2.minutes.ago)
    newer = Conversation.create!(company: company, student: second_student)
    first_message = newer.messages.create!(sender: company, body: "最初の送信")
    first_message.update_columns(created_at: 1.minute.ago)
    reply = newer.messages.create!(sender: second_student, body: "学生からの返信")
    reply.update_columns(created_at: 10.seconds.ago)
    other = Conversation.create!(company: other_company, student: first_student)
    other.messages.create!(sender: other_company, body: "他社の送信")
    login_as(company)

    get "/api/v1/company/conversations"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data").pluck("id")).to eq([newer.id, older.id])
    expect(response.parsed_body.dig("data", 0)).to include(
      "student" => { "id" => second_student.id, "name" => "学生 二郎" },
      "latest_message_excerpt" => "学生からの返信",
      "latest_sender_role" => "student"
    )
    expect(response.body).not_to include(first_student.email, other_company.email)
  end

  it "returns an empty list when the company has no messages" do
    login_as(company)
    get "/api/v1/company/conversations"
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data")).to eq([])
  end

  it "rejects students" do
    login_as(first_student)
    get "/api/v1/company/conversations"
    expect(response).to have_http_status(:forbidden)
  end
end
