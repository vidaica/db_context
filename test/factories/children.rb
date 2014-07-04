FactoryGirl.define do
  
  factory :child do
    
    sequence(:name){|n| "Child #{n}"}
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
    
    #after(:build)  { |child| puts(child.name) }
    
  end
     
end