class CreateChildrenTable < ActiveRecord::Migration
  def change
    create_table :children do |t|
      t.integer :father_id
      t.string :name
    end
  end
end
