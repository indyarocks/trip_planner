# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20140524120958) do

  create_table "stations", force: true do |t|
    t.string   "name",       null: false
    t.string   "code",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "stations", ["code"], name: "UNIQUE", unique: true

  create_table "train_schedules", force: true do |t|
    t.integer  "train_number"
    t.string   "station_code",         limit: 20
    t.integer  "distance_from_origin"
    t.string   "arrival_time",         limit: 10
    t.string   "departure_time",       limit: 10
    t.boolean  "sun",                             default: false
    t.boolean  "mon",                             default: false
    t.boolean  "tue",                             default: false
    t.boolean  "wed",                             default: false
    t.boolean  "thu",                             default: false
    t.boolean  "fri",                             default: false
    t.boolean  "sat",                             default: false
    t.integer  "journey_day",          limit: 3,                  null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "train_schedules", ["station_code"], name: "INDEX2"
  add_index "train_schedules", ["train_number", "station_code"], name: "UNIQUE_INDEX", unique: true

  create_table "trains", force: true do |t|
    t.integer  "number",     null: false
    t.string   "name",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
