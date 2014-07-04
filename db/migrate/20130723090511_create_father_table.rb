class CreateFatherTable < ActiveRecord::Migration
  def change
    create_table :fathers do |t|
      t.integer :boss_id
      t.string :name
      t.string :nickname
      t.string :complexion
      t.integer :number
    end
  end
end