class ActiveRecord::Base   
  
  include DbContext::MethodDefiner
  
  def method_missing(method_name, *args, &block)                         
    
    definers = {
      /^has_(\d+)_([a-zA-Z]+)$/             => 'has_n_associates',
      /^random_update_(\d+)_([a-zA-Z]+)$/   => 'random_update_n_associates',
      /^has_([a-zA-Z]+)$/                   => 'has_associates'
    }
    
    define_missing_method( method_name, definers, *args, &block )            
        
  end
  
  def belongs_to(associate_object, associate = nil)
    
    associate = associate.nil? ? associate_object.class.name.downcase : associate        
    self.send("#{associate}=", associate_object)
    self.save!
    self
    
  end
  
  def has(associate_objects, reverse_associate = nil)
    
    reverse_associate = reverse_associate.nil? ? self.class.name.downcase : reverse_associate
    
    associate_objects.each do |object|
      object.send("#{reverse_associate}=", self)
      object.save!
    end
    
    self
    
  end
  
  private  
  
  def random_update_n_associates(method_name, matches)
    
    self.class.class_eval do
      
      define_method method_name do |*args|
          
        [self].send(method_name,*args)
        
        self
        
      end
    
    end
    
  end
  
  
  def has_associates(method_name, matches)      
    
    self.class.class_eval do
      
      define_method method_name do |data, *args|
        
        self.associate = matches[1]
            
        self.directives, self.options = split_arguments(args)
        
        if insertion_using_import?
        
          create_associate_objects_by_import(data)
        
        else
          
          create_associate_objects_by_factory_girl(data)
          
        end
        
      end
      
    end
    
  end        
  
  
  def has_n_associates(method_name, matches)     
    
    self.class.class_eval do
      
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
            
    delete_existing_associate_objects
            
    import_associate_objects associate_objects
    
    return_self? ? self : associate_class.where([" #{associate_foreign_key} = (?)", self.id ]).to_a      
    
  end
  
  def create_associate_objects_by_factory_girl(data)
    
  end  
    
  def reflection()
    self.class.reflections[associate.to_sym]
  end
  
  def import_associate_objects(associate_objects)
    associate_class.import associate_objects
  end  
  
  def delete_existing_associate_objects()
    associate_class.where([" #{associate_foreign_key} = (?)", self.id ]).delete_all
  end  
  
end

class FailedImportError < Exception
end

class InvalidCreateMethod < Exception
end
