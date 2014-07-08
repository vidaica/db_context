class ActiveRecord::Base   
  
  include DbContext::MethodDefiner
  
  def method_missing(method_name, *args, &block)                         
    
    definers = {
      /^has_(\d+)_([a-zA-Z_]+)$/             => 'has_n___association_name__',
      /^random_update_(\d+)_([a-zA-Z_]+)$/   => 'random_update_n___association_name__',
      /^has_([a-zA-Z_]+)$/                   => 'has___association_name__'
    }
    
    define_missing_method( method_name, definers, *args, &block )            
        
  end
  
  def belongs_to(associated_object, *args)
    
    self.directives, self.options = split_arguments(args)
    
    self.association_name = options[:association].nil? ? associated_object.class.name.downcase : options[:association]
    self.send("#{self.association_name}=", associated_object)
    self.save!
    
    return_self? ? self : associated_object
    
  end
  
  def has(associated_objects, *args)
    
    self.directives, self.options = split_arguments(args)
          
    self.association_name = options[:association].nil? ? associated_objects.first.class.name.downcase.pluralize : options[:association]
    
    associated_objects.each do |object|      
      self.send(self.association_name) << object
    end
    
    return_self? ? self : associated_objects
    
  end
  
  private  
  
  def random_update_n___association_name__(method_name, matches)
    
    klass_eval do
      
      define_method method_name do |*args|
          
        [self].send(method_name,*args)
        
        self
        
      end
    
    end
    
  end
  
  
  def has___association_name__(method_name, matches)      
    
    klass_eval do
      
      define_method method_name do |data, *args|
        
        self.association_name = matches[1]
            
        self.directives, self.options = split_arguments(args)
        
        delete_existing_associated_objects
        
        if insertion_using_import?
        
          create_associated_objects_by_import(data)
        
        else
          
          create_associated_objects_by_factory_girl(data)
          
        end
        
        return_self? ? self : associated_class.where([" #{association_foreign_key} = (?)", self.id ]).to_a
        
      end
      
    end
    
  end        
  
  
  def has_n___association_name__(method_name, matches)     
    
    klass_eval do
      
      define_method method_name do |*args|
        
        self.directives, self.options = split_arguments(args)
        
        result = [self].send(method_name,*args)
        
        return_self? ? result.first : result
        
      end
      
    end
    
  end
  
  
  def create_associated_objects_by_import(data)                        
    
    associated_objects = []
        
    data.each do |data_item|                
      associated_object = FactoryGirl.build(*prepend_values_to_factory(data_item))
      associated_object.send( "#{association_foreign_key}=", self.id )
      associated_objects << associated_object            
    end                    
            
    import_associated_objects associated_objects       
    
  end
  
  def create_associated_objects_by_factory_girl(data)
        
    data.each do |data_item|            
      send(self.association_name) << FactoryGirl.build(*prepend_values_to_factory(data_item))
    end
    
  end  
    
  def reflection()
    self.class.reflections[self.association_name.to_sym]
  end   
  
  def delete_existing_associated_objects()
    associated_class.where([" #{association_foreign_key} = (?)", self.id ]).destroy_all
  end  
  
end
