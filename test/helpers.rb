module Helpers
  
  def assert_array_of(arr, count, type)
    arr.count.should be count
    arr.each do |item|
      item.class.should be type
    end
  end
    
end