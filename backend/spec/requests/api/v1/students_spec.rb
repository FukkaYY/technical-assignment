require "rails_helper"

RSpec.describe "Students", type: :request do
  before { Rails.cache.clear }

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

  def create_student(index, created_at: index.minutes.ago)
    user = User.create!(
      email: format("student%02d@example.com", index),
      password: "password123",
      password_confirmation: "password123",
      role: :student
    )
    profile = user.create_student_profile!(
      name: "学生 #{index}",
      school_name: "デモ大学",
      graduation_year: Time.zone.today.year + 1,
      desired_role: "エンジニア",
      skills: ["Ruby", "Rails", "PostgreSQL", "Docker"],
      self_introduction: "あ" * 130
    )
    profile.update_columns(created_at: created_at)
    user
  end

  def csrf_token
    get "/api/v1/csrf"
    response.parsed_body.dig("data", "csrf_token")
  end

  def login_as(user, role: user.role)
    post "/api/v1/session",
      params: { session: { email: user.email, password: "password123", role: role } },
      headers: { "X-CSRF-Token" => csrf_token },
      as: :json
    expect(response).to have_http_status(:ok)
  end

  it "returns students newest first in pages of 20 without private fields" do
    students = 25.times.map { |index| create_student(index + 1, created_at: (index + 1).minutes.ago) }
    login_as(company)

    get "/api/v1/students", params: { page: 1 }

    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body.fetch("data").length).to eq(20)
    expect(body.fetch("meta")).to eq(
      "page" => 1,
      "per_page" => 20,
      "total_count" => 25,
      "total_pages" => 2,
      "has_previous" => false,
      "has_next" => true
    )

    first = body.fetch("data").first
    expect(first).to include(
      "id" => students.first.id,
      "name" => "学生 1",
      "skills" => ["Ruby", "Rails", "PostgreSQL"],
      "skills_count" => 4,
      "self_introduction_excerpt" => (("あ" * 119) + "…")
    )
    expect(first.fetch("registered_at")).to match(/Z\z/)
    expect(first).not_to have_key("email")
    expect(first).not_to have_key("password_digest")
    expect(first).not_to have_key("user_id")

    get "/api/v1/students", params: { page: 2 }
    expect(response.parsed_body.fetch("data").length).to eq(5)
    expect(response.parsed_body.fetch("meta")).to include(
      "page" => 2,
      "has_previous" => true,
      "has_next" => false
    )
  end

  it "uses page one by default" do
    create_student(1)
    login_as(company)

    get "/api/v1/students"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("meta", "page")).to eq(1)
  end

  it "excludes hidden profiles from lists, searches, pagination, and direct details until republished" do
    visible_student = create_student(1, created_at: 1.minute.ago)
    hidden_student = create_student(2, created_at: 2.minutes.ago)
    hidden_student.student_profile.update!(visible_to_companies: false)
    login_as(company)

    get "/api/v1/students"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data").pluck("id")).to eq([visible_student.id])
    expect(response.parsed_body.fetch("meta")).to include("total_count" => 1, "total_pages" => 1)

    get "/api/v1/students/#{hidden_student.id}"
    expect(response).to have_http_status(:not_found)

    hidden_student.student_profile.update!(visible_to_companies: true)
    get "/api/v1/students/#{hidden_student.id}"
    expect(response).to have_http_status(:ok)
  end

  it "combines school and profile filters" do
    university = School.create!(name: "東京大学", school_type: "university")
    graduate_school = School.create!(name: "大阪大学大学院", school_type: "graduate_school")
    ruby_student = create_student(1, created_at: 1.minute.ago)
    ruby_student.student_profile.update!(
      last_name: "山田",
      first_name: "花子",
      school: university,
      graduation_year: Time.zone.today.year + 2,
      desired_role: "バックエンドエンジニア",
      interested_roles: ["ソフトウェアエンジニア"],
      skills: ["Ruby", "PostgreSQL"]
    )
    create_student(2, created_at: 2.minutes.ago).student_profile.update!(
      last_name: "佐藤",
      first_name: "太郎",
      school: graduate_school,
      graduation_year: Time.zone.today.year + 1,
      desired_role: "フロントエンドエンジニア",
      interested_roles: ["UI・UXデザイナー"],
      skills: ["TypeScript"]
    )
    login_as(company)

    get "/api/v1/students", params: {
      school_type: " university ",
      school_id: university.id,
      graduation_year: Time.zone.today.year + 2,
      interested_role: " ソフトウェアエンジニア "
    }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data").pluck("id")).to eq([ruby_student.id])
    expect(response.parsed_body.fetch("meta")).to include("total_count" => 1, "total_pages" => 1)
  end

  it "returns an empty result with pagination metadata when no profile matches" do
    create_student(1)
    school = School.create!(name: "該当者のいない大学", school_type: "university")
    login_as(company)

    get "/api/v1/students", params: { school_id: school.id }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data")).to eq([])
    expect(response.parsed_body.fetch("meta")).to include("total_count" => 0, "total_pages" => 0)
  end

  it "returns 422 for invalid search filters" do
    login_as(company)

    [
      { params: { school_type: "存在しない学校種別" }, field: "school_type" },
      { params: { school_id: "not-an-id" }, field: "school_id" },
      { params: { school_id: 99_999 }, field: "school_id" },
      { params: { interested_role: "存在しない職種" }, field: "interested_role" },
      { params: { graduation_year: "not-a-year" }, field: "graduation_year" },
      { params: { graduation_year: Time.zone.today.year + 3 }, field: "graduation_year" }
    ].each do |example|
      get "/api/v1/students", params: example.fetch(:params)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("errors", 0)).to include(
        "field" => example.fetch(:field),
        "code" => "invalid"
      )
    end
  end

  it "returns 422 for an invalid page" do
    login_as(company)

    ["0", "-1", "abc", "1.5"].each do |page|
      get "/api/v1/students", params: { page: page }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("errors", 0)).to include(
        "field" => "page",
        "code" => "invalid"
      )
    end
  end

  it "returns an empty list for a positive page beyond the result set" do
    create_student(1)
    login_as(company)

    get "/api/v1/students", params: { page: 2 }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data")).to eq([])
    expect(response.parsed_body.fetch("meta")).to include(
      "page" => 2,
      "total_pages" => 1,
      "has_previous" => true,
      "has_next" => false
    )
  end

  it "returns total_pages zero when there are no students" do
    login_as(company)

    get "/api/v1/students"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data")).to eq([])
    expect(response.parsed_body.fetch("meta")).to include(
      "page" => 1,
      "total_count" => 0,
      "total_pages" => 0,
      "has_previous" => false,
      "has_next" => false
    )
  end

  it "requires authentication" do
    get "/api/v1/students"

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body.dig("errors", 0, "code")).to eq("unauthenticated")
  end

  it "rejects a student role" do
    student = create_student(1)
    login_as(student)

    get "/api/v1/students"

    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig("errors", 0, "code")).to eq("forbidden")
  end

  describe "GET /api/v1/students/:id" do
    it "returns the complete public profile without private fields" do
      student = create_student(1)
      login_as(company)

      get "/api/v1/students/#{student.id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data")).to eq(
        "id" => student.id,
        "name" => "学生 1",
        "school_name" => "デモ大学",
        "school_type" => nil,
        "faculty_name" => nil,
        "department_name" => nil,
        "graduation_year" => Time.zone.today.year + 1,
        "desired_role" => "エンジニア",
        "interested_roles" => [],
        "skills" => ["Ruby", "Rails", "PostgreSQL", "Docker"],
        "self_introduction" => ("あ" * 130),
        "self_promotion" => ("あ" * 130),
        "student_achievement" => "",
        "research_summary" => "",
        "english_skills" => "",
        "qualifications" => ""
      )
      expect(response.body).not_to include(student.email)
      expect(response.body).not_to include("password_digest")
      expect(response.parsed_body.fetch("data")).not_to have_key("user_id")
    end

    it "returns 404 for a missing student" do
      login_as(company)

      get "/api/v1/students/999999"

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body.dig("errors", 0)).to include(
        "field" => "student",
        "code" => "not_found"
      )
    end

    it "requires authentication" do
      student = create_student(1)

      get "/api/v1/students/#{student.id}"

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body.dig("errors", 0, "code")).to eq("unauthenticated")
    end

    it "rejects a student role" do
      student = create_student(1)
      login_as(student)

      get "/api/v1/students/#{student.id}"

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body.dig("errors", 0, "code")).to eq("forbidden")
    end
  end
end
