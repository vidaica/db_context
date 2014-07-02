class CreateChildrenTable < ActiveRecord::Migration
  def change
    create_table :children do |t|
      t.integer :father_id
      t.integer :foster_father_id
      t.string :name
      t.string :nickname
      t.string :gender
    end
  end
end
