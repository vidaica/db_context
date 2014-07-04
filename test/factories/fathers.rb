FactoryGirl.define do
  
  factory :father do
    sequence(:name){|n| "Father #{n}"}
    nickname "Nick"
    complexion 'none'
    
    trait :white do
      complexion 'white'
    end
    
    factory :another_father do
      name "Another Father"
      nickname "Another Nick"
    end
    
    factory :white_father do
      complexion 'white'
    end
    
    factory :invalid_father do
      name ""
    end
    
  end
  
end  