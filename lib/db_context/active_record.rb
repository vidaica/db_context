class ActiveRecord::Base   
  
  include DbContext::MethodDefiner
  
  def method_missing(method_name, *args, &block)                         
    
    definers = {
      /^has_(\d+)_([a-zA-Z]+)$/             => 'define_has_n_associates',
      /^random_update_(\d+)_([a-zA-Z]+)$/   => 'define_random_update_n_associates',
      /^has_([a-zA-Z]+)$/                   => 'define_has_associates'
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
  
  
  def define_random_update_n_associates(method_name, matches)
    
    self.class.class_eval do
      
      define_method method_name do |*args|
          
        [self].send(method_name,*args)
        
      end
    
    end
    
  end
  
  
  def define_has_associates(method_name, matches)      
    
    associate = matches[1]
    
    self.class.class_eval do
      
      define_method method_name do |data, factory = nil, return_what = :self|
        
        create_associates(associate, data, factory, return_what)               
        
      end
      
    end
    
  end        
  
  
  def define_has_n_associates(method_name, matches)
    
    number_of_associate_objects = matches[1].to_i
    
    associate = matches[2]    
    
    self.class.class_eval do
      
      define_method method_name do |factory = nil, return_what = :self|
        
        create_associates(associate, number_of_associate_objects, factory, return_what)                               
        
      end
      
    end
    
  end
  
  
  def create_associates(associate, data, factory, return_what)
    
    return_associate_objects = ([factory, return_what] & return_next_symbols ).any?        
                        
    factory = ( return_next_symbols.include?(factory) || factory.nil? ) ? associate.singularize.to_sym : factory
    
    associate_objects = []
    
    data = data.class == Fixnum ? [{}]*data : data
    
    data.each do |data_item|
      associate_object = FactoryGirl.build factory, data_item
      associate_object.send( "#{associate_foreign_key(associate)}=", self.id )
      associate_objects << associate_object            
    end     
            
    delete_existing_associate_objects associate
            
    import_associate_objects associate, associate_objects
    
    if return_associate_objects
      associate_class(associate).where([" #{associate_foreign_key(associate)} = (?)", self.id ]).to_a
    else
      self
    end
    
  end   
  
  def associate_foreign_key(associate)
    reflection(associate).foreign_key
  end
  
  def associate_class(associate)
    reflection(associate).klass
  end  
  
  def reflection(associate)
    self.class.reflections[associate.to_sym]
  end
  
  def import_associate_objects(associate, associate_objects)
    associate_class(associate).import associate_objects
  end  
  
  def delete_existing_associate_objects(associate)
    associate_class(associate).where([" #{associate_foreign_key(associate)} = (?)", self.id ]).delete_all
  end
  
  def return_next_symbols
    [:here]
  end
  
end

class FailedImportError < Exception
end

class InvalidCreateMethod < Exception
end
