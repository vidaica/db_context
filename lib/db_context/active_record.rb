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
    
    klass_eval do
        
      define_method method_name do |*args, &block|
               
        self.directives, self.options = split_arguments(args)
        
        args[0] = [args[0]]
        
        result = [self].send(method_name,*args, &block)
                
        return_self? ? self : result.first
        
      end
      
    end
    
  end
  
  def makes___association_name__(method_name, matches)
    
    klass_eval do
      
      define_method method_name do |*args, &block|
                  
        self.directives, self.options = split_arguments(args)          
         
        result = [self].send(method_name,*args, &block)
                 
        return_self? ? self : result.first
       
      end
     
    end
    
  end
  
  def add___association_name__(method_name, matches)
    
    klass_eval do
      
      define_method method_name do |*args, &block|
                  
        self.directives, self.options = split_arguments(args)
                
        result = [self].send(method_name,*args, &block)
                
        return_self? ? self : result
       
      end
     
    end
    
  end
  
  def has_n___association_name__(method_name, matches)
    
    klass_eval do
      
      define_method method_name do |*args, &block|
                  
        self.directives, self.options = split_arguments(args)
                
        result = [self].send(method_name,*args, &block)
                
        return_self? ? self : result
       
      end
     
    end
    
  end
  
  def random_update_n___association_name__(method_name, matches)
    
    klass_eval do
      
      define_method method_name do |*args, &block|
                  
        self.directives, self.options = split_arguments(args)
                
        result = [self].send(method_name,*args, &block)
                
        return_self? ? self : result
       
      end
     
    end
    
  end
  
  def has___association_name__(method_name, matches)      
    
    klass_eval do
      
      define_method method_name do |*args, &block|
                  
        self.directives, self.options = split_arguments(args)
        
        data = args.shift
        
        if args[-1].is_a?(Hash)
           args[-1][:data] = data
        else
          args.push(:data => data)
        end
                
        result = [self].send("has_#{data.count}_#{matches[1]}",*args, &block)
                
        return_self? ? self : result
       
      end
     
    end
    
  end    
      
  def reflection()
    self.class.reflections[self.association_name.to_sym]
  end
  
end
