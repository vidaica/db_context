RSpec::Matchers.define :be_an_array_of do |expected_class|
  
  match do |actual|
    (actual.is_a?(Array) && actual.map(&:class).uniq == [expected_class]) && (actual.count == @expected_count)
  end

  chain :with do |expected_count|
    @expected_count = expected_count
  end
  
  chain :items do
  end
  
  failure_message_for_should do |actual|
    
    if ! actual.is_a?(Array)      
      "expected an array but got #{actual.class.name}: #{actual.inspect}"
    else      
      "expected #{actual.map{|item| item.class.name}} would be an array of #{expected_class.name} with #{@expected_count} items"
    end
      
  end
  
end