class Father < ActiveRecord::Base
  has_many :children, class_name: 'Child'
  
  validates :name, presence: true
  
end