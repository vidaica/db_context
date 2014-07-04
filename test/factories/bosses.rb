FactoryGirl.define do
  
  factory :boss do
    sequence(:name){|n| "Boss #{n}"}    
  end
  
end  