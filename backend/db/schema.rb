# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_08_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "company_profiles", force: :cascade do |t|
    t.string "company_name", limit: 200, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_company_profiles_on_user_id", unique: true
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.bigint "student_id", null: false
    t.bigint "student_last_read_message_id"
    t.datetime "updated_at", null: false
    t.index ["company_id", "student_id"], name: "index_conversations_on_company_id_and_student_id", unique: true
    t.index ["company_id"], name: "index_conversations_on_company_id"
    t.index ["student_id"], name: "index_conversations_on_student_id"
    t.index ["student_last_read_message_id"], name: "index_conversations_on_student_last_read_message_id"
    t.check_constraint "company_id <> student_id", name: "conversations_distinct_participants"
    t.check_constraint "student_last_read_message_id IS NULL OR student_last_read_message_id > 0", name: "conversations_student_last_read_message_id_positive"
  end

  create_table "departments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "faculty_id", null: false
    t.string "name", limit: 200, null: false
    t.datetime "updated_at", null: false
    t.index ["faculty_id", "name"], name: "index_departments_on_faculty_id_and_name", unique: true
    t.index ["faculty_id"], name: "index_departments_on_faculty_id"
  end

  create_table "faculties", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", limit: 200, null: false
    t.bigint "school_id", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "name"], name: "index_faculties_on_school_id_and_name", unique: true
    t.index ["school_id"], name: "index_faculties_on_school_id"
  end

  create_table "job_posting_interests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_posting_id", null: false
    t.bigint "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["job_posting_id"], name: "index_job_posting_interests_on_job_posting_id"
    t.index ["student_id", "job_posting_id"], name: "index_job_posting_interests_on_student_id_and_job_posting_id", unique: true
    t.index ["student_id"], name: "index_job_posting_interests_on_student_id"
  end

  create_table "job_postings", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.text "requirements", null: false
    t.string "role_name", limit: 100, null: false
    t.string "status", default: "published", null: false
    t.string "title", limit: 120, null: false
    t.datetime "updated_at", null: false
    t.string "work_location", limit: 200, null: false
    t.index ["company_id"], name: "index_job_postings_on_company_id"
    t.index ["status", "created_at", "id"], name: "index_job_postings_on_status_and_created_at_and_id"
    t.check_constraint "status::text = ANY (ARRAY['published'::character varying::text, 'closed'::character varying::text])", name: "job_postings_status_check"
  end

  create_table "messages", force: :cascade do |t|
    t.text "body", null: false
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.bigint "sender_id", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "created_at", "id"], name: "index_messages_on_conversation_id_and_created_at_and_id"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "schedule_proposals", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "ends_at", null: false
    t.string "location", limit: 200, null: false
    t.text "note", default: "", null: false
    t.datetime "starts_at", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.datetime "student_seen_at"
    t.index ["conversation_id", "created_at", "id"], name: "index_schedule_proposals_on_conversation_and_created_at"
    t.index ["conversation_id"], name: "index_schedule_proposals_on_conversation_id"
    t.check_constraint "ends_at > starts_at", name: "schedule_proposals_valid_period"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying::text, 'accepted'::character varying::text, 'declined'::character varying::text, 'cancelled'::character varying::text])", name: "schedule_proposals_status_check"
  end

  create_table "schools", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", limit: 200, null: false
    t.string "school_type", limit: 30, null: false
    t.datetime "updated_at", null: false
    t.index ["school_type", "name"], name: "index_schools_on_school_type_and_name", unique: true
  end

  create_table "student_profiles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "department_id"
    t.string "desired_role", limit: 100, null: false
    t.text "english_skills", default: "", null: false
    t.bigint "faculty_id"
    t.string "first_name", limit: 50
    t.integer "graduation_year", null: false
    t.jsonb "interested_roles", default: [], null: false
    t.string "last_name", limit: 50
    t.string "name", limit: 101, null: false
    t.text "qualifications", default: "", null: false
    t.text "research_summary", default: "", null: false
    t.bigint "school_id"
    t.string "school_name", limit: 200, null: false
    t.text "self_introduction", null: false
    t.text "self_promotion", default: "", null: false
    t.jsonb "skills", default: [], null: false
    t.text "student_achievement", default: "", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.boolean "visible_to_companies", default: true, null: false
    t.index ["department_id"], name: "index_student_profiles_on_department_id"
    t.index ["faculty_id"], name: "index_student_profiles_on_faculty_id"
    t.index ["school_id"], name: "index_student_profiles_on_school_id"
    t.index ["user_id"], name: "index_student_profiles_on_user_id", unique: true
    t.index ["visible_to_companies", "created_at", "id"], name: "index_student_profiles_on_visibility_and_list_order"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
    t.check_constraint "role::text = ANY (ARRAY['student'::character varying::text, 'company'::character varying::text])", name: "users_role_check"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id", on_delete: :cascade
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id", on_delete: :cascade
  add_foreign_key "company_profiles", "users", on_delete: :cascade
  add_foreign_key "conversations", "users", column: "company_id", on_delete: :cascade
  add_foreign_key "conversations", "users", column: "student_id", on_delete: :cascade
  add_foreign_key "departments", "faculties", on_delete: :cascade
  add_foreign_key "faculties", "schools", on_delete: :cascade
  add_foreign_key "job_posting_interests", "job_postings", on_delete: :cascade
  add_foreign_key "job_posting_interests", "users", column: "student_id", on_delete: :cascade
  add_foreign_key "job_postings", "users", column: "company_id", on_delete: :cascade
  add_foreign_key "messages", "conversations", on_delete: :cascade
  add_foreign_key "messages", "users", column: "sender_id", on_delete: :cascade
  add_foreign_key "schedule_proposals", "conversations", on_delete: :cascade
  add_foreign_key "student_profiles", "departments", on_delete: :restrict
  add_foreign_key "student_profiles", "faculties", on_delete: :restrict
  add_foreign_key "student_profiles", "schools", on_delete: :restrict
  add_foreign_key "student_profiles", "users", on_delete: :cascade
end
