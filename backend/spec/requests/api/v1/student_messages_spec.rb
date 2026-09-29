require "rails_helper"

RSpec.describe "Student messages", type: :request do
  before { Rails.cache.clear }

  let!(:company) { create_company("company@example.com", "デモ企業株式会社") }
  let!(:other_company) { create_company("other@example.com", "別企業株式会社") }
  let!(:student) { create_student("student@example.com", "山田 太郎") }

  def create_company(email, name)
    user = User.create!(email: email, password: "password123", password_confirmation: "password123", role: :company)
    user.create_company_profile!(company_name: name)
    user
  end

  def create_student(email, name)
    user = User.create!(email: email, password: "password123", password_confirmation: "password123", role: :student)
    user.create_student_profile!(
      name: name,
      school_name: "デモ大学",
      graduation_year: Time.zone.today.year + 1,
      desired_role: "エンジニア",
      skills: ["Ruby"],
      self_introduction: "自己紹介"
    )
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

  def send_message(body)
    post "/api/v1/students/#{student.id}/messages",
      params: { message: { body: body } },
      headers: { "X-CSRF-Token" => csrf_token },
      as: :json
  end

  it "creates a conversation and normalized first message atomically" do
    login_as(company)

    expect { send_message("  はじめまして  ") }
      .to change(Conversation, :count).by(1)
      .and change(Message, :count).by(1)

    expect(response).to have_http_status(:created)
    expect(response.parsed_body.dig("data", "message", "body")).to eq("はじめまして")
    expect(Conversation.last).to have_attributes(company: company, student: student)
  end

  it "reuses the conversation and returns history oldest first" do
    login_as(company)
    send_message("最初のメッセージ")
    first_id = response.parsed_body.dig("data", "conversation_id")
    send_message("次のメッセージ")

    expect(response.parsed_body.dig("data", "conversation_id")).to eq(first_id)
    expect(Conversation.count).to eq(1)

    get "/api/v1/students/#{student.id}/messages"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "student")).to eq("id" => student.id, "name" => "山田 太郎")
    expect(response.parsed_body.dig("data", "messages").pluck("body")).to eq(["最初のメッセージ", "次のメッセージ"])
    expect(response.parsed_body.dig("data", "messages").pluck("sender_role")).to eq(["company", "company"])
  end

  it "includes student replies in the company's conversation history" do
    conversation = Conversation.create!(company: company, student: student)
    conversation.messages.create!(sender: company, body: "企業から送信")
    conversation.messages.create!(sender: student, body: "学生から返信")
    login_as(company)

    get "/api/v1/students/#{student.id}/messages"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "messages").map { |message| [message["body"], message["sender_role"]] }).to eq([
      ["企業から送信", "company"],
      ["学生から返信", "student"]
    ])
  end

  it "keeps an existing conversation available after the student hides their profile" do
    conversation = Conversation.create!(company: company, student: student)
    conversation.messages.create!(sender: company, body: "公開中のメッセージ")
    student.student_profile.update!(visible_to_companies: false)
    login_as(company)

    get "/api/v1/students/#{student.id}/messages"
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "messages").pluck("body")).to eq(["公開中のメッセージ"])

    send_message("非公開後のメッセージ")
    expect(response).to have_http_status(:created)
  end

  it "does not allow a company to start a conversation with a hidden student" do
    student.student_profile.update!(visible_to_companies: false)
    login_as(company)

    expect { send_message("新規メッセージ") }.not_to change(Conversation, :count)
    expect(response).to have_http_status(:not_found)
  end

  it "does not expose another company's conversation" do
    conversation = Conversation.create!(company: other_company, student: student)
    conversation.messages.create!(sender: other_company, body: "別企業のメッセージ")
    login_as(company)

    get "/api/v1/students/#{student.id}/messages"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "conversation_id")).to be_nil
    expect(response.parsed_body.dig("data", "messages")).to eq([])
  end

  it "rejects invalid bodies without leaving an empty conversation" do
    login_as(company)

    ["   ", "a" * 2_001].each do |body|
      expect { send_message(body) }.not_to change(Conversation, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("errors", 0, "field")).to eq("body")
    end
  end

  it "requires a company session" do
    get "/api/v1/students/#{student.id}/messages"
    expect(response).to have_http_status(:unauthorized)

    login_as(student)
    get "/api/v1/students/#{student.id}/messages"
    expect(response).to have_http_status(:forbidden)
  end

  it "returns 404 for a missing student" do
    login_as(company)

    get "/api/v1/students/999999/messages"

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig("errors", 0, "code")).to eq("not_found")
  end
end
