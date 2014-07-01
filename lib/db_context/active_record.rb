class ActiveRecord::Base   
  
  include DbContext::MethodDefiner
  
  def method_missing(method_name, *args, &block)                         
    
    definers = {
      /^has_(\d+)_([a-zA-Z_]+)$/             => 'has_n_associates',
      /^random_update_(\d+)_([a-zA-Z_]+)$/   => 'random_update_n_associates',
      /^has_([a-zA-Z_]+)$/                   => 'has_associates'
    }
    
    define_missing_method( method_name, definers, *args, &block )            
        
  end
  
  def belongs_to(associate_object, *args)
    
    self.directives, self.options = split_arguments(args)
    
    associate = options[:associate].nil? ? associate_object.class.name.downcase : options[:associate]
    self.send("#{associate}=", associate_object)
    self.save!
    
    return_self? ? self : associate_object
    
  end
  
  def has(associate_objects, *args)
    
    self.directives, self.options = split_arguments(args)
          
    associate = options[:associate].nil? ? associate_objects.first.class.name.downcase.pluralize : options[:associate]
    
    associate_objects.each do |object|      
      self.send(associate) << object
    end
    
    return_self? ? self : associate_objects
    
  end
  
  private  
  
  def random_update_n_associates(method_name, matches)
    
    klass_eval do
      
      define_method method_name do |*args|
          
        [self].send(method_name,*args)
        
        self
        
      end
    
    end
    
  end
  
  
  def has_associates(method_name, matches)      
    
    klass_eval do
      
      define_method method_name do |data, *args|
        
        self.associate = matches[1]
            
        self.directives, self.options = split_arguments(args)
        
        delete_existing_associate_objects
        
        if insertion_using_import?
        
          create_associate_objects_by_import(data)
        
        else
          
          create_associate_objects_by_factory_girl(data)
          
        end
        
        return_self? ? self : associate_class.where([" #{associate_foreign_key} = (?)", self.id ]).to_a
        
      end
      
    end
    
  end        
  
  
  def has_n_associates(method_name, matches)     
    
    klass_eval do
      
      define_method method_name do |*args|
        
        self.directives, self.options = split_arguments(args)
        
        result = [self].send(method_name,*args)
        
        return_self? ? result.first : result
        
      end
      
    end
    
  end
  
  
  def create_associate_objects_by_import(data)                        
    
    associate_objects = []        
    
    data.each do |data_item|
      associate_object = FactoryGirl.build factory, data_item
      associate_object.send( "#{associate_foreign_key}=", self.id )
      associate_objects << associate_object            
    end                    
            
    import_associate_objects associate_objects       
    
  end
  
  def create_associate_objects_by_factory_girl(data)
    
    data.each do |data_item|      
      send(associate) << FactoryGirl.build(factory, data_item)
    end
    
  end  
    
  def reflection()
    self.class.reflections[associate.to_sym]
  end   
  
  def delete_existing_associate_objects()
    associate_class.where([" #{associate_foreign_key} = (?)", self.id ]).delete_all
  end  
  
end
