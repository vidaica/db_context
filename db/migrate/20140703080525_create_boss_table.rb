class CreateBossTable < ActiveRecord::Migration
  def change
    create_table :bosses do |t|
      t.string :name     
    end
  end
end
