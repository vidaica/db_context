class Fixnum
      
  include DbContext::MethodDefiner
  
  def method_missing(method_name, *args, &block)
    
    definers = {
      /^[A-Z]/  => 'define_active_record_creating'      
    }
    
    define_missing_method( method_name, definers, *args, &block ) 
    
  end
  
  private
  
  def define_active_record_creating(method_name, matches)    
    self.class.class_eval do
      define_method method_name do |create_method = :import, factory = nil, import_options = {}|
        method_name.to_s.singularize.constantize.send("create_#{self}", create_method, factory, import_options)
      end        
    end
  end
  
end