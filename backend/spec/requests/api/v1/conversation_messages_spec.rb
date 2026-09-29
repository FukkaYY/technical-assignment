require "rails_helper"

RSpec.describe "Conversation messages", type: :request do
  before { Rails.cache.clear }

  let!(:student) { create_student("student@example.com") }
  let!(:other_student) { create_student("other-student@example.com") }
  let!(:company) { create_company("company@example.com") }
  let!(:conversation) do
    Conversation.create!(company: company, student: student).tap do |record|
      record.messages.create!(sender: company, body: "企業からのメッセージ")
    end
  end

  def create_student(email)
    user = User.create!(email: email, password: "password123", password_confirmation: "password123", role: :student)
    user.create_student_profile!(
      name: "デモ学生",
      school_name: "デモ大学",
      graduation_year: Time.zone.today.year + 1,
      desired_role: "エンジニア",
      skills: ["Ruby"],
      self_introduction: "自己紹介"
    )
    user
  end

  def create_company(email)
    user = User.create!(email: email, password: "password123", password_confirmation: "password123", role: :company)
    user.create_company_profile!(company_name: "デモ企業株式会社")
    user
  end

  def csrf_token
    get "/api/v1/csrf"
    response.parsed_body.dig("data", "csrf_token")
  end

  def login_as(user)
    post "/api/v1/session",
      params: { session: { email: user.email, password: "password123", role: user.role } },
      headers: { "X-CSRF-Token" => csrf_token },
      as: :json
    expect(response).to have_http_status(:ok)
  end

  def reply(body, token: csrf_token)
    post "/api/v1/conversations/#{conversation.id}/messages",
      params: { message: { body: body } },
      headers: { "X-CSRF-Token" => token },
      as: :json
  end

  it "adds a normalized student reply to an existing conversation" do
    login_as(student)

    expect { reply("  返信メッセージです  ") }.to change(Message, :count).by(1)

    expect(response).to have_http_status(:created)
    expect(response.parsed_body.dig("data", "message")).to include(
      "body" => "返信メッセージです",
      "sender_role" => "student"
    )
    expect(Message.last).to have_attributes(conversation: conversation, sender: student)
  end

  it "rejects an invalid body without adding a message" do
    login_as(student)

    ["   ", "a" * 2_001].each do |body|
      expect { reply(body) }.not_to change(Message, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("errors", 0, "field")).to eq("body")
    end
  end

  it "returns 404 for another student's conversation" do
    login_as(other_student)

    reply("閲覧できない会話への返信")

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig("errors", 0, "code")).to eq("not_found")
  end

  it "requires a student session" do
    reply("未ログイン")
    expect(response).to have_http_status(:unauthorized)

    login_as(company)
    reply("企業ロール")
    expect(response).to have_http_status(:forbidden)
  end

  it "rejects a request without a valid CSRF token" do
    login_as(student)

    reply("CSRFなし", token: nil)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("errors", 0, "field")).to eq("csrf_token")
  end
end
