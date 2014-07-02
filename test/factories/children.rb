FactoryGirl.define do
  
  factory :child do
    
    name "Child"
    nickname "Nick"
    gender "None"
    
    trait :male do
      gender 'male'
    end
    
    factory :another_child do
      name "Another Child"
      nickname "Another Nick"
    end
    
    factory :invalid_child do
      name ""
    end
    
  end
     
end