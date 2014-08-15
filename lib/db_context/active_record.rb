class ActiveRecord::Base   
  
  include DbContext::MethodDefiner
  
  def method_missing(method_name, *args, &block)                         
    
    definers = {
      /^belongs?_to(_[0-9a-zA-Z_]+)?$/           => 'belongs_to___association_name__',
      /^makes?_([0-9a-zA-Z_]+)$/                 => 'makes___association_name__',
      /^adds?_([0-9a-zA-Z_]+)$/                  => 'add___association_name__',
      /^(has|have)_(\d+)_([0-9a-zA-Z_]+)$/       => 'has_n___association_name__',
      /^random_update_(\d+)_([0-9a-zA-Z_]+)$/    => 'random_update_n___association_name__',              
      /^has_([0-9a-zA-Z_]+)$/                    => 'has___association_name__'
    }
    
    define_missing_method( method_name, definers, *args, &block )            
        
  end
    
  private
  
  def belongs_to___association_name__(method_name, matches)
        
    _delegate_method_to_array(method_name, true) do |args|
      args[0] = [args[0]]
      [args]
    end
    
  end
  
  def makes___association_name__(method_name, matches)
        
    _delegate_method_to_array(method_name, true)
    
  end
  
  def add___association_name__(method_name, matches)
        
    _delegate_method_to_array(method_name)
    
  end
  
  def has_n___association_name__(method_name, matches)
        
    _delegate_method_to_array(method_name)
    
  end
  
  def random_update_n___association_name__(method_name, matches)
        
    _delegate_method_to_array(method_name)
    
  end  
  
  def has___association_name__(method_name, matches)      
        
    _delegate_method_to_array(method_name) do |args|
      
      data = args.shift
      
      if args[-1].is_a?(Hash)
         args[-1][:data] = data
      else
        args.push(:data => data)
      end
              
      [args, "has_#{data.count}_#{matches[1]}"]
    
    end
    
  end
  
  def _delegate_method_to_array(method_name, return_first_assoc_object = false)
    
    klass_eval do
      
      define_method method_name do |*args, &block|
                  
        self.directives, self.options = split_arguments(args)
        
        args, target_method_name = yield(args) if block_given?
        
        target_method_name = target_method_name || method_name
                    
        result = [self].send(target_method_name,*args, &block)          
        
        return_self? ? self : ( return_first_assoc_object ? result.first : result )
       
      end
      
    end
    
  end
  
end
