class CreateFatherTable < ActiveRecord::Migration
  def change
    create_table :fathers do |t|
      t.string :name
      t.string :nickname
      t.integer :number
    end
  end 
end