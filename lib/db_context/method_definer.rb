module DbContext
  
  module MethodDefiner
    
    alias_method :method_missing_before_db_context, :method_missing
    
    private
     
    def define_missing_method(method_name, definers, *args, &block)
          
      definers.each do |method_patern, defining_method|
        
        matches = method_name.to_s.match(method_patern)
        
        if matches
          self.send(defining_method, method_name, matches)
          return self.send(method_name,*args) #execute the newly defined method and return the result
        end
        
      end
      
      method_missing_before_db_context(method_name, *args, &block)
      
    end
     
  end

end