class Child < ActiveRecord::Base
  
  belongs_to :father
  
  belongs_to :foster_father, :foreign_key => 'foster_father_id', :class_name => 'Father'
  
  validates :name, presence: true
  
end