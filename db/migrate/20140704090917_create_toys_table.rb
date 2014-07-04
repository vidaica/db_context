class CreateToysTable < ActiveRecord::Migration
  def change
    create_table :toys do |t|
      t.integer :child_id
      t.string :name     
    end
  end
end
