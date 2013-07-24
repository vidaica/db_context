FactoryGirl.define do
  
  factory :father do
    name "Father"
    
    factory :another_father do      
    end
    
    factory :invalid_father do
      name ""
    end
    
  end
  
end  