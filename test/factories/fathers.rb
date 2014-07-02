FactoryGirl.define do
  
  factory :father do
    name "Father"
    nickname "Nick"
    complexion 'none'
    
    trait :white do
      complexion 'white'
    end
    
    factory :another_father do
      name "Another Father"
      nickname "Another Nick"
    end
    
    factory :invalid_father do
      name ""
    end
    
  end
  
end  