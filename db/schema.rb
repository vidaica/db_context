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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140704090917) do

  create_table "bosses", :force => true do |t|
    t.string "name"
  end

  create_table "children", :force => true do |t|
    t.integer "father_id"
    t.integer "foster_father_id"
    t.string  "name"
    t.string  "nickname"
    t.string  "gender"
  end

  create_table "fathers", :force => true do |t|
    t.integer "boss_id"
    t.string  "name"
    t.string  "nickname"
    t.string  "complexion"
    t.integer "number"
  end

  create_table "toys", :force => true do |t|
    t.integer "child_id"
    t.string  "name"
  end

end
