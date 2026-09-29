require "rails_helper"

RSpec.describe "Education options", type: :request do
  it "returns schools with their selectable faculties and departments without authentication" do
    school = School.create!(name: "デモ大学", school_type: "university")
    faculty = school.faculties.create!(name: "情報学部")
    faculty.departments.create!(name: "情報学科")

    get "/api/v1/education_options"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "schools", 0)).to include(
      "name" => "デモ大学",
      "school_type" => "university",
      "faculties" => [include("name" => "情報学部", "departments" => [include("name" => "情報学科")])]
    )
  end
end
