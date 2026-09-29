require "rails_helper"

RSpec.describe "Student registrations", type: :request do
  let!(:school) { School.create!(name: "サンプル大学", school_type: "university") }
  let!(:faculty) { school.faculties.create!(name: "工学部") }
  let!(:department) { faculty.departments.create!(name: "情報工学科") }
  let(:valid_attributes) do
    {
      email: " Student@Example.com ",
      password: "password123",
      password_confirmation: "password123",
      last_name: " 山田 ",
      first_name: " 太郎 ",
      school_id: school.id,
      faculty_id: faculty.id,
      department_id: department.id,
      graduation_year: Time.zone.today.year + 1,
      interested_roles: [" ソフトウェアエンジニア ", "データサイエンティスト"],
      skills: [" Ruby ", "", "Ruby", "PostgreSQL"],
    }
  end

  def csrf_token
    get "/api/v1/csrf"
    response.parsed_body.dig("data", "csrf_token")
  end

  def register(attributes = valid_attributes, token: csrf_token)
    post "/api/v1/student_registrations",
      params: { student_registration: attributes },
      headers: { "X-CSRF-Token" => token },
      as: :json
  end

  it "creates a normalized student and profile atomically and logs the student in" do
    expect { register }.to change(User, :count).by(1).and change(StudentProfile, :count).by(1)

    expect(response).to have_http_status(:created)
    expect(response.parsed_body.dig("data", "user")).to include(
      "email" => "student@example.com",
      "role" => "student"
    )
    expect(response.parsed_body.dig("data", "user")).not_to have_key("password_digest")
    expect(response.parsed_body.dig("data", "student_profile")).to include(
      "name" => "山田 太郎",
      "last_name" => "山田",
      "first_name" => "太郎",
      "school_name" => "サンプル大学",
      "faculty_name" => "工学部",
      "department_name" => "情報工学科",
      "desired_role" => "ソフトウェアエンジニア、データサイエンティスト",
      "interested_roles" => ["ソフトウェアエンジニア", "データサイエンティスト"],
      "skills" => ["Ruby", "PostgreSQL"],
      "self_introduction" => ""
    )

    get "/api/v1/me"
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "user", "email")).to eq("student@example.com")
  end

  it "rejects a mutating request without a CSRF token" do
    register(valid_attributes, token: nil)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("errors", 0)).to include(
      "field" => "csrf_token",
      "code" => "invalid"
    )
    expect(User.count).to eq(0)
  end

  it "does not accept a client supplied company role" do
    register(valid_attributes.merge(role: "company"))

    expect(response).to have_http_status(:created)
    expect(User.last).to be_student
  end

  it "rejects a duplicate email regardless of case" do
    register
    register(valid_attributes.merge(email: "STUDENT@example.COM"))

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.fetch("errors")).to include(
      include("field" => "email", "code" => "taken")
    )
    expect(User.count).to eq(1)
  end

  it "rolls back the user when the profile is invalid" do
    expect { register(valid_attributes.merge(last_name: "")) }.not_to change(User, :count)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(StudentProfile.count).to eq(0)
  end

  it "rejects a faculty that does not belong to the selected school" do
    other_school = School.create!(name: "別大学", school_type: "university")
    other_faculty = other_school.faculties.create!(name: "文学部")

    register(valid_attributes.merge(faculty_id: other_faculty.id, department_id: nil))

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.fetch("errors")).to include(include("field" => "faculty_id", "code" => "invalid"))
  end

  it "rejects a mismatched password confirmation" do
    register(valid_attributes.merge(password_confirmation: "different-password"))

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.fetch("errors")).to include(
      include("field" => "password_confirmation", "code" => "confirmation")
    )
  end

  it "rejects a graduation year outside the allowed range" do
    register(valid_attributes.merge(graduation_year: Time.zone.today.year + 11))

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.fetch("errors")).to include(
      include("field" => "graduation_year", "code" => "less_than_or_equal_to")
    )
  end

  it "rejects invalid interested role combinations" do
    register(valid_attributes.merge(interested_roles: ["まだ決めていない", "ソフトウェアエンジニア"]))

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.fetch("errors")).to include(include("field" => "interested_roles", "code" => "invalid"))
  end

  it "logs the current student out" do
    register
    delete "/api/v1/session", headers: { "X-CSRF-Token" => csrf_token }

    expect(response).to have_http_status(:no_content)

    get "/api/v1/me"
    expect(response).to have_http_status(:unauthorized)
  end
end
