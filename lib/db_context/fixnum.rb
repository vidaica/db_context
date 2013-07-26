class Fixnum
      
  include DbContext::MethodDefiner
  
  def method_missing(method_name, *args, &block)
    
    definers = {
      /^[A-Z]/  => 'active_record_creating'      
    }
    
    define_missing_method( method_name, definers, *args, &block ) 
    
  end
  
  private
  
  def active_record_creating(method_name, matches) 
    self.class.class_eval do
      
      define_method method_name do |*args|
        
        method_name.to_s.singularize.constantize.send("create_#{self}", *args)
        
      end
      
    end
  end
  
end