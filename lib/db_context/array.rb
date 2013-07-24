class Array
       
  include DbContext::MethodDefiner
  
  def method_missing(method_name, *args, &block)
              
    definers = {
      /^each_has_(\d+)_([a-zA-Z]+)$/            => 'define_each_has_n_associates',
      /^has_(\d+)_([a-zA-Z]+)$/                 => 'define_has_n_associates',
      /^random_update_(\d+)_([a-zA-Z]+)$/       => 'define_random_update_n_associates',     
    }
    
    define_missing_method( method_name, definers, *args, &block )
        
  end
  
  def belongs_to(associate_objects, associate_name = nil, return_what = :self)
    
    return_associate_objects = ([associate_name, return_what] & return_next_symbols ).any?
    
    associate_name = nil if return_next_symbols.include?(associate_name)
    
    self.zip(associate_objects).each do |pair|
      
      record, associate_object = pair
      record.belongs_to associate_object, associate_name
      
    end
    
    return_associate_objects ? associate_objects : self
    
  end   
  
  private   
  
  def define_random_update_n_associates(method_name, matches)
    
    number_of_updated_associate_objects = matches[1].to_i
    
    associate = matches[2]
    
    self.class.class_eval do
    
      define_method method_name do |updated_attributes|
                              
        id_hash = {}               
        
        associate_ids = associate_class(associate)        
        .where( [ "#{associate_foreign_key(associate)} IN (?)", self.map(&:id) ] )
        .each do |associate_object|
          
          foreign_key_value = associate_object.send("#{associate_foreign_key(associate)}")
          id_hash[foreign_key_value] = [] if id_hash[foreign_key_value].nil?
          id_hash[foreign_key_value] << associate_object.id
          
        end               
        
        updated_associate_object_ids = []              
        
        id_hash.each_pair do |key, associate_object_ids|
                    
          updated_associate_object_ids << associate_object_ids.sample(number_of_updated_associate_objects)
          
        end               
        
        associate_class(associate).where( [" id IN (?) ", updated_associate_object_ids.flatten ] ).update_all(updated_attributes)
                                                                  
      end
    
    end
    
  end
  
  
  def define_has_n_associates(method_name, matches)
    
    number_of_associate_objects = matches[1].to_i
    
    associate = matches[2]
    
    self.class.class_eval do
      
      define_method method_name do |factory = nil, return_what = :self|
        
        return_associate_objects = ([factory, return_what] & return_next_symbols ).any?        
                        
        factory = ( return_next_symbols.include?(factory) || factory.nil? ) ? associate.singularize.to_sym : factory
                
        associate_objects = []
        
        allocating_scheme = [number_of_associate_objects/self.count]*self.count
        
        ( number_of_associate_objects - (number_of_associate_objects/self.count)*self.count ).times do
          allocating_scheme[rand(self.count-1)] += 1
        end
        
        self.zip(allocating_scheme).each do |pair|
          
          object, number_of_allocated_associate_objects = pair
          
          number_of_allocated_associate_objects.times do            
            associate_object = FactoryGirl.build factory
            associate_object.send( "#{associate_foreign_key(associate)}=", object.id )
            associate_objects << associate_object            
          end
          
        end               
        
        associate_class(associate).delete_all
        
        associate_class(associate).import associate_objects
              
        return_associate_objects ? associate_class(associate).last(number_of_associate_objects) : self
        
      end
      
    end
    
  end    
  
  def define_each_has_n_associates(method_name, matches)
    
    number_of_associate_objects = matches[1].to_i
    
    associate = matches[2]
    
    self.class.class_eval do
      
      define_method method_name do |factory = nil, return_what = :self|
        
        real_factory = return_next_symbols.include?(factory) ? nil : factory
        
        associate_objects = []               
        
        self.each do |object|
          
          number_of_associate_objects.times do
            associate_object = FactoryGirl.build ( real_factory.nil? ? associate.singularize : real_factory ).to_sym
            associate_object.send( "#{associate_foreign_key(associate)}=", object.id )
            associate_objects << associate_object           
          end                  
          
        end              
                
        associate_class(associate)
        .where([" #{associate_foreign_key(associate)} IN (?)", self.map(&:id) ])
        .delete_all
                        
        associate_class(associate).import associate_objects               
        
        if ( [factory, return_what] & return_next_symbols ).any?
          associate_class(associate)
          .where([" #{associate_foreign_key(associate)} IN (?)", self.map(&:id) ])
          .order("id asc")
          .to_a
        else
          self
        end
                
      end
      
    end
    
  end
  
  def associate_foreign_key(associate)
    reflection(associate).foreign_key
  end
  
  def associate_class(associate)
    reflection(associate).klass
  end  
  
  def reflection(associate)
    self.first.class.reflections[associate.to_sym]
  end
  
  def return_next_symbols
    [:here]
  end
  
end