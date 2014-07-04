FactoryGirl.define do
  
  factory :toy do    
    sequence(:name){|n| "Toy #{n}"}    
  end
  
end