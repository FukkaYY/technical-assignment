require "rails_helper"
require "base64"

RSpec.describe "Job postings", type: :request do
  before { Rails.cache.clear }

  let!(:company) { create_user("company@example.com", :company) }
  let!(:other_company) { create_user("other@example.com", :company) }
  let!(:student) { create_user("student@example.com", :student) }
  let(:valid_attributes) do
    { title: "Railsエンジニア募集", role_name: "バックエンドエンジニア", work_location: "東京・週2日リモート", description: "プロダクト開発を担当します。", requirements: "Rubyの学習経験" }
  end

  def create_user(email, role)
    user = User.create!(email: email, password: "password123", password_confirmation: "password123", role: role)
    if role == :company
      user.create_company_profile!(company_name: "#{email}株式会社")
    else
      user.create_student_profile!(name: "学生", school_name: "大学", graduation_year: Time.zone.today.year + 1, desired_role: "エンジニア", skills: ["Ruby"], self_introduction: "自己紹介")
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

  def uploaded_thumbnail
    tempfile = Tempfile.new(["thumbnail", ".png"])
    tempfile.binmode
    tempfile.write(Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="))
    tempfile.rewind
    Rack::Test::UploadedFile.new(tempfile.path, "image/png", true, original_filename: "thumbnail.png")
  end

  it "lets a company create, list, update, and close its posting" do
    login_as(company)

    expect {
      post "/api/v1/company/job_postings", params: { job_posting: valid_attributes }, headers: { "X-CSRF-Token" => csrf_token }, as: :json
    }.to change(JobPosting, :count).by(1)
    expect(response).to have_http_status(:created)
    posting_id = response.parsed_body.dig("data", "id")

    get "/api/v1/company/job_postings"
    expect(response.parsed_body.fetch("data").pluck("id")).to eq([posting_id])

    patch "/api/v1/company/job_postings/#{posting_id}", params: { job_posting: valid_attributes.merge(title: "更新後") }, headers: { "X-CSRF-Token" => csrf_token }, as: :json
    expect(response.parsed_body.dig("data", "title")).to eq("更新後")

    patch "/api/v1/company/job_postings/#{posting_id}/close", headers: { "X-CSRF-Token" => csrf_token }, as: :json
    expect(response.parsed_body.dig("data", "status")).to eq("closed")
  end

  it "returns validation errors without creating a posting" do
    login_as(company)
    expect {
      post "/api/v1/company/job_postings", params: { job_posting: valid_attributes.merge(title: " ") }, headers: { "X-CSRF-Token" => csrf_token }, as: :json
    }.not_to change(JobPosting, :count)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("errors", 0, "field")).to eq("title")
  end

  it "lets a company attach, replace, and remove a thumbnail" do
    login_as(company)
    post "/api/v1/company/job_postings", params: { job_posting: valid_attributes.merge(thumbnail: uploaded_thumbnail) }, headers: { "X-CSRF-Token" => csrf_token }

    expect(response).to have_http_status(:created)
    posting_id = response.parsed_body.dig("data", "id")
    expect(response.parsed_body.dig("data", "thumbnail_url")).to eq("/api/v1/job_postings/#{posting_id}/thumbnail")

    get "/api/v1/job_postings/#{posting_id}/thumbnail"
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("image/png")

    patch "/api/v1/company/job_postings/#{posting_id}", params: { job_posting: valid_attributes.merge(remove_thumbnail: true) }, headers: { "X-CSRF-Token" => csrf_token }
    expect(response.parsed_body.dig("data", "thumbnail_url")).to be_nil
  end

  it "does not expose or update another company's posting" do
    posting = other_company.job_postings.create!(valid_attributes)
    login_as(company)

    get "/api/v1/company/job_postings/#{posting.id}"
    expect(response).to have_http_status(:not_found)
    patch "/api/v1/company/job_postings/#{posting.id}", params: { job_posting: valid_attributes.merge(title: "変更") }, headers: { "X-CSRF-Token" => csrf_token }, as: :json
    expect(response).to have_http_status(:not_found)
    expect(posting.reload.title).to eq("Railsエンジニア募集")
  end

  it "shows only published postings to students, newest first" do
    older = company.job_postings.create!(valid_attributes.merge(title: "古い募集"))
    newer = other_company.job_postings.create!(valid_attributes.merge(title: "新しい募集"))
    older.update_columns(created_at: 1.day.ago)
    company.job_postings.create!(valid_attributes.merge(title: "終了済み", status: :closed))
    login_as(student)

    get "/api/v1/job_postings"
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data").pluck("id")).to eq([newer.id, older.id])
    expect(response.parsed_body.dig("data", 0, "company", "company_name")).to eq("other@example.com株式会社")
    expect(response.parsed_body.dig("data", 0, "interested")).to be(false)
  end

  it "lets a student add, filter, and remove interested postings" do
    interested_posting = company.job_postings.create!(valid_attributes)
    other_posting = other_company.job_postings.create!(valid_attributes.merge(title: "別の募集"))
    login_as(student)

    expect {
      post "/api/v1/job_postings/#{interested_posting.id}/interest", headers: { "X-CSRF-Token" => csrf_token }
    }.to change(JobPostingInterest, :count).by(1)
    expect(response).to have_http_status(:created)

    post "/api/v1/job_postings/#{interested_posting.id}/interest", headers: { "X-CSRF-Token" => csrf_token }
    expect(JobPostingInterest.count).to eq(1)

    get "/api/v1/job_postings", params: { interested: "true" }
    expect(response.parsed_body.fetch("data").pluck("id")).to eq([interested_posting.id])
    expect(response.parsed_body.dig("data", 0, "interested")).to be(true)
    expect(response.parsed_body.fetch("data").pluck("id")).not_to include(other_posting.id)

    delete "/api/v1/job_postings/#{interested_posting.id}/interest", headers: { "X-CSRF-Token" => csrf_token }
    expect(response).to have_http_status(:ok)
    expect(JobPostingInterest.count).to eq(0)
  end

  it "keeps interest data but hides a posting after it closes" do
    posting = company.job_postings.create!(valid_attributes)
    student.job_posting_interests.create!(job_posting: posting)
    posting.closed!
    login_as(student)

    get "/api/v1/job_postings", params: { interested: "true" }
    expect(response.parsed_body.fetch("data")).to be_empty
    expect(student.job_posting_interests.exists?(job_posting: posting)).to be(true)
  end

  it "returns 404 for a closed posting on the student API" do
    posting = company.job_postings.create!(valid_attributes.merge(status: :closed))
    login_as(student)
    get "/api/v1/job_postings/#{posting.id}"
    expect(response).to have_http_status(:not_found)
  end

  it "enforces role authorization and CSRF protection" do
    token = csrf_token
    get "/api/v1/company/job_postings"
    expect(response).to have_http_status(:unauthorized)

    login_as(student)
    get "/api/v1/company/job_postings"
    expect(response).to have_http_status(:forbidden)

    delete "/api/v1/session", headers: { "X-CSRF-Token" => csrf_token }
    login_as(company)
    post "/api/v1/company/job_postings", params: { job_posting: valid_attributes }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)

    delete "/api/v1/session", headers: { "X-CSRF-Token" => csrf_token }
    login_as(company)
    get "/api/v1/job_postings"
    expect(response).to have_http_status(:forbidden)
  end
end
