require "rails_helper"

RSpec.describe Message, type: :model do
  let!(:company) do
    User.create!(email: "company@example.com", password: "password123", password_confirmation: "password123", role: :company)
  end
  let!(:student) do
    User.create!(email: "student@example.com", password: "password123", password_confirmation: "password123", role: :student)
  end
  let!(:outsider) do
    User.create!(email: "other@example.com", password: "password123", password_confirmation: "password123", role: :company)
  end
  let(:conversation) { Conversation.create!(company: company, student: student) }

  it "normalizes and accepts a participant message" do
    message = described_class.create!(conversation: conversation, sender: company, body: "  はじめまして  ")

    expect(message.body).to eq("はじめまして")
  end

  it "rejects an empty or overlong body" do
    empty_message = described_class.new(conversation: conversation, sender: company, body: "  ")
    long_message = described_class.new(conversation: conversation, sender: company, body: "a" * 2_001)

    expect(empty_message).not_to be_valid
    expect(empty_message.errors.of_kind?(:body, :blank)).to be(true)
    expect(long_message).not_to be_valid
    expect(long_message.errors.of_kind?(:body, :too_long)).to be(true)
  end

  it "rejects a sender outside the conversation" do
    message = described_class.new(conversation: conversation, sender: outsider, body: "本文")

    expect(message).not_to be_valid
    expect(message.errors.of_kind?(:sender, :invalid)).to be(true)
  end
end
