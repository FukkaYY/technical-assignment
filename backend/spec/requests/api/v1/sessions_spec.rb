require "rails_helper"

RSpec.describe "Sessions", type: :request do
  before do
    Rails.cache.clear
  end

  let!(:company) do
    user = User.create!(
      email: "company@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :company
    )
    user.create_company_profile!(company_name: "デモ企業株式会社")
    user
  end

  let!(:student) do
    user = User.create!(
      email: "student@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :student
    )
    user.create_student_profile!(
      name: "山田 太郎",
      school_name: "サンプル大学",
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

  def login(email: "company@example.com", password: "password123", role: "company")
    post "/api/v1/session",
      params: { session: { email: email, password: password, role: role } },
      headers: { "X-CSRF-Token" => csrf_token },
      as: :json
  end

  it "logs a company in and returns its profile" do
    login(email: " COMPANY@example.com ")

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "user")).to include(
      "id" => company.id,
      "email" => "company@example.com",
      "role" => "company"
    )
    expect(response.parsed_body.dig("data", "company_profile")).to include(
      "user_id" => company.id,
      "company_name" => "デモ企業株式会社"
    )
    expect(response.parsed_body.dig("data", "student_profile")).to be_nil

    get "/api/v1/me"
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "user", "id")).to eq(company.id)
  end

  it "returns the same error for a wrong email, password, or role" do
    [
      { email: "missing@example.com" },
      { password: "wrong-password" },
      { email: student.email, role: "company" }
    ].each do |overrides|
      login(**overrides)

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body.fetch("errors")).to eq([
        {
          "field" => "base",
          "code" => "invalid_credentials",
          "message" => "メールアドレスまたはパスワードが正しくありません"
        }
      ])
    end
  end

  it "supports the shared endpoint for a student role" do
    login(email: student.email, role: "student")

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "user", "role")).to eq("student")
    expect(response.parsed_body.dig("data", "student_profile", "user_id")).to eq(student.id)
    expect(response.parsed_body.dig("data", "company_profile")).to be_nil
  end

  it "rate limits the sixth attempt from the same IP within a minute" do
    5.times { login(password: "wrong-password") }
    login(password: "wrong-password")

    expect(response).to have_http_status(:too_many_requests)
    expect(response.parsed_body.dig("errors", 0, "code")).to eq("rate_limited")
  end
end
