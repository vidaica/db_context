FactoryGirl.define do
  
  factory :child do
    
    name "Child"
    nickname "Nick"
    
    factory :another_child do
      name "Another Child"
      nickname "Another Nick"
    end
    
    factory :invalid_child do
      name ""
    end
    
  end
     
end