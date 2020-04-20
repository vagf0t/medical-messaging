# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20200420093353) do

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "inboxes", force: :cascade do |t|
    t.integer "user_id"
    t.integer "unread_emails"
    t.index ["user_id"], name: "index_inboxes_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text     "body"
    t.integer  "outbox_id"
    t.integer  "inbox_id"
    t.boolean  "read",       default: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["inbox_id"], name: "index_messages_on_inbox_id"
    t.index ["outbox_id"], name: "index_messages_on_outbox_id"
  end

  create_table "outboxes", force: :cascade do |t|
    t.integer "user_id"
    t.index ["user_id"], name: "index_outboxes_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "user_id"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean  "is_patient", default: true
    t.boolean  "is_doctor",  default: false
    t.boolean  "is_admin",   default: false
    t.string   "first_name"
    t.string   "last_name"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

end
