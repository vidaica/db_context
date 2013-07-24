FactoryGirl.define do
  
  factory :child do
    
    name "Child"
    
    factory :another_child do
      name "Another Child"
    end
    
    factory :invalid_child do
      name ""
    end
    
  end
     
end