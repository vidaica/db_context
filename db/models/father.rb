class Father < ActiveRecord::Base
  
  has_many :children
  has_many :foster_children, class_name: 'Child', foreign_key: 'foster_father_id'
  
  validates :name, presence: true
  
end