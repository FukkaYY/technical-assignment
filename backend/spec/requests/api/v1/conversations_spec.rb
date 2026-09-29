require "rails_helper"

RSpec.describe "Conversations", type: :request do
  before { Rails.cache.clear }

  let!(:student) { create_student("student@example.com", "山田 太郎") }
  let!(:other_student) { create_student("other-student@example.com", "佐藤 花子") }
  let!(:first_company) { create_company("first@example.com", "第一株式会社") }
  let!(:second_company) { create_company("second@example.com", "第二株式会社") }

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

  def create_company(email, name)
    user = User.create!(email: email, password: "password123", password_confirmation: "password123", role: :company)
    user.create_company_profile!(company_name: name)
    user
  end

  def create_conversation(company:, recipient:, bodies:)
    conversation = Conversation.create!(company: company, student: recipient)
    bodies.each_with_index do |body, index|
      message = conversation.messages.create!(sender: company, body: body)
      message.update_columns(created_at: (bodies.length - index).minutes.ago)
    end
    conversation
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

  it "returns only the student's conversations with newest activity first" do
    older = create_conversation(company: first_company, recipient: student, bodies: ["古いメッセージ"])
    newer = create_conversation(company: second_company, recipient: student, bodies: ["新しいメッセージ"])
    newer.messages.last.update_columns(created_at: 10.seconds.ago)
    create_conversation(company: first_company, recipient: other_student, bodies: ["他の学生宛て"])
    login_as(student)

    get "/api/v1/conversations"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data").pluck("id")).to eq([newer.id, older.id])
    expect(response.parsed_body.dig("data", 0, "company")).to eq(
      "company_name" => "第二株式会社"
    )
    expect(response.parsed_body.dig("data", 0, "unread_count")).to eq(1)
    expect(response.body).not_to include(second_company.email)
  end

  it "counts only unread company messages in the list" do
    conversation = create_conversation(company: first_company, recipient: student, bodies: ["既読", "未読"])
    first_message = conversation.messages.first
    conversation.messages.create!(sender: student, body: "学生からの返信")
    conversation.update!(student_last_read_message_id: first_message.id)
    login_as(student)

    get "/api/v1/conversations"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", 0, "unread_count")).to eq(1)
  end

  it "reports unseen pending schedule proposals and sorts by their activity" do
    older = create_conversation(company: first_company, recipient: student, bodies: ["新しい本文"])
    newer = create_conversation(company: second_company, recipient: student, bodies: ["古い本文"])
    older.messages.last.update_columns(created_at: 2.minutes.ago)
    newer.messages.last.update_columns(created_at: 3.minutes.ago)
    unseen = newer.schedule_proposals.create!(starts_at: 2.days.from_now, ends_at: 2.days.from_now + 1.hour, location: "オンライン")
    unseen.update_columns(created_at: 1.minute.ago)
    cancelled = newer.schedule_proposals.create!(starts_at: 3.days.from_now, ends_at: 3.days.from_now + 1.hour, location: "来社", status: :cancelled)
    cancelled.update_columns(created_at: 4.minutes.ago)
    login_as(student)

    get "/api/v1/conversations"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data").pluck("id")).to eq([newer.id, older.id])
    expect(response.parsed_body.dig("data", 0, "unseen_schedule_proposal_count")).to eq(1)
    expect(response.parsed_body.dig("data", 0, "latest_activity_at")).to eq(unseen.created_at.utc.iso8601)
  end

  it "returns an empty list when the student has no conversations" do
    login_as(student)

    get "/api/v1/conversations"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data")).to eq([])
  end

  it "returns the student's conversation messages oldest first" do
    conversation = create_conversation(company: first_company, recipient: student, bodies: ["最初", "次"])
    login_as(student)

    get "/api/v1/conversations/#{conversation.id}"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "company", "company_name")).to eq("第一株式会社")
    expect(response.parsed_body.dig("data", "messages").pluck("body")).to eq(["最初", "次"])
    expect(response.parsed_body.dig("data", "messages").pluck("sender_role")).to eq(["company", "company"])
    expect(response.body).not_to include(first_company.email)
  end

  it "returns 404 instead of exposing another student's conversation" do
    conversation = create_conversation(company: first_company, recipient: other_student, bodies: ["本文"])
    login_as(student)

    get "/api/v1/conversations/#{conversation.id}"

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig("errors", 0, "code")).to eq("not_found")
  end

  it "marks messages through the displayed message as read" do
    conversation = create_conversation(company: first_company, recipient: student, bodies: ["最初", "次"])
    latest_message = conversation.messages.last
    login_as(student)

    patch "/api/v1/conversations/#{conversation.id}/read",
      params: { conversation: { message_id: latest_message.id } },
      headers: { "X-CSRF-Token" => csrf_token },
      as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "unread_count")).to eq(0)
    expect(conversation.reload.student_last_read_message_id).to eq(latest_message.id)
  end

  it "marks schedule proposals through the displayed proposal as seen" do
    conversation = create_conversation(company: first_company, recipient: student, bodies: ["本文"])
    first = conversation.schedule_proposals.create!(starts_at: 2.days.from_now, ends_at: 2.days.from_now + 1.hour, location: "オンライン")
    second = conversation.schedule_proposals.create!(starts_at: 3.days.from_now, ends_at: 3.days.from_now + 1.hour, location: "来社")
    login_as(student)

    patch "/api/v1/conversations/#{conversation.id}/schedule_proposals_seen",
      params: { conversation: { schedule_proposal_id: first.id } },
      headers: { "X-CSRF-Token" => csrf_token },
      as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "unseen_schedule_proposal_count")).to eq(1)
    expect(first.reload.student_seen_at).to be_present
    expect(second.reload.student_seen_at).to be_nil
  end

  it "does not mark another conversation's schedule proposal as seen" do
    conversation = create_conversation(company: first_company, recipient: student, bodies: ["本文"])
    other_conversation = create_conversation(company: second_company, recipient: student, bodies: ["別会話"])
    proposal = other_conversation.schedule_proposals.create!(starts_at: 2.days.from_now, ends_at: 2.days.from_now + 1.hour, location: "オンライン")
    login_as(student)

    patch "/api/v1/conversations/#{conversation.id}/schedule_proposals_seen",
      params: { conversation: { schedule_proposal_id: proposal.id } },
      headers: { "X-CSRF-Token" => csrf_token },
      as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(proposal.reload.student_seen_at).to be_nil
  end

  it "hides another student's conversation when marking schedule proposals as seen" do
    conversation = create_conversation(company: first_company, recipient: other_student, bodies: ["本文"])
    proposal = conversation.schedule_proposals.create!(starts_at: 2.days.from_now, ends_at: 2.days.from_now + 1.hour, location: "オンライン")
    login_as(student)

    patch "/api/v1/conversations/#{conversation.id}/schedule_proposals_seen",
      params: { conversation: { schedule_proposal_id: proposal.id } },
      headers: { "X-CSRF-Token" => csrf_token },
      as: :json

    expect(response).to have_http_status(:not_found)
    expect(proposal.reload.student_seen_at).to be_nil
  end

  it "requires CSRF protection when marking schedule proposals as seen" do
    conversation = create_conversation(company: first_company, recipient: student, bodies: ["本文"])
    proposal = conversation.schedule_proposals.create!(starts_at: 2.days.from_now, ends_at: 2.days.from_now + 1.hour, location: "オンライン")
    login_as(student)

    patch "/api/v1/conversations/#{conversation.id}/schedule_proposals_seen",
      params: { conversation: { schedule_proposal_id: proposal.id } },
      as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(proposal.reload.student_seen_at).to be_nil
  end

  it "does not mark another conversation's message as read" do
    conversation = create_conversation(company: first_company, recipient: student, bodies: ["本文"])
    other_conversation = create_conversation(company: second_company, recipient: student, bodies: ["別会話"])
    login_as(student)

    patch "/api/v1/conversations/#{conversation.id}/read",
      params: { conversation: { message_id: other_conversation.messages.last.id } },
      headers: { "X-CSRF-Token" => csrf_token },
      as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(conversation.reload.student_last_read_message_id).to be_nil
  end

  it "hides another student's conversation when marking it read" do
    conversation = create_conversation(company: first_company, recipient: other_student, bodies: ["本文"])
    login_as(student)

    patch "/api/v1/conversations/#{conversation.id}/read",
      params: { conversation: { message_id: conversation.messages.last.id } },
      headers: { "X-CSRF-Token" => csrf_token },
      as: :json

    expect(response).to have_http_status(:not_found)
  end

  it "requires CSRF protection when marking a conversation as read" do
    conversation = create_conversation(company: first_company, recipient: student, bodies: ["本文"])
    login_as(student)

    patch "/api/v1/conversations/#{conversation.id}/read",
      params: { conversation: { message_id: conversation.messages.last.id } },
      as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(conversation.reload.student_last_read_message_id).to be_nil
  end

  it "requires a student session" do
    get "/api/v1/conversations"
    expect(response).to have_http_status(:unauthorized)

    login_as(first_company)
    get "/api/v1/conversations"
    expect(response).to have_http_status(:forbidden)
  end

  it "requires a student session when marking a conversation as read" do
    conversation = create_conversation(company: first_company, recipient: student, bodies: ["本文"])
    token = csrf_token

    patch "/api/v1/conversations/#{conversation.id}/read",
      params: { conversation: { message_id: conversation.messages.last.id } },
      headers: { "X-CSRF-Token" => token },
      as: :json
    expect(response).to have_http_status(:unauthorized)

    login_as(first_company)
    patch "/api/v1/conversations/#{conversation.id}/read",
      params: { conversation: { message_id: conversation.messages.last.id } },
      headers: { "X-CSRF-Token" => csrf_token },
      as: :json
    expect(response).to have_http_status(:forbidden)
  end
end
