class Child < ActiveRecord::Base
  
  belongs_to :father
  
  validates :name, presence: true
  
end