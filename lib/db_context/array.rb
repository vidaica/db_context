class Array   
       
  include DbContext::MethodDefiner
  
  def method_missing(method_name, *args, &block)
              
    definers = {
      /^each_has_(\d+)_([a-zA-Z_]+)$/            => 'each_has_n_associates',
      /^has_(\d+)_([a-zA-Z_]+)$/                 => 'has_n_associates',
      /^random_update_(\d+)_([a-zA-Z_]+)$/       => 'random_update_n_associates'
    }
    
    define_missing_method( method_name, definers, *args, &block )
        
  end
  
  def belongs_to(associate_objects, *args)
    
    associate_objects = [associate_objects] if ! associate_objects.is_a?(Array)
    
    self.directives, self.options = split_arguments(args)
    
    allocating_scheme = generate_allocating_scheme(self.count, associate_objects.count)
    
    indexes = (0...self.count).to_a
    
    associate_objects.zip(allocating_scheme).each do |associate_object, number_of_items|
           
      indexes.shift(number_of_items).each do |index|
        self[index].belongs_to associate_object, :associate => options[:associate]
      end    
      
    end
        
    return_self? ? self : associate_objects
    
  end
  
  def has(associate_objects, *args)
    
    self.directives, self.options = split_arguments(args)
          
    associate = options[:associate].nil? ? associate_objects.first.class.name.downcase.pluralize : options[:associate]      
    
    allocating_scheme = generate_allocating_scheme(associate_objects.count, self.count)
    
    indexes = (0...associate_objects.count).to_a
    
    self.zip(allocating_scheme).each do |item, number_of_associate_objects|
           
      indexes.shift(number_of_associate_objects).each do |index|        
        item.send(associate) << associate_objects[index]
      end    
      
    end
            
    return_self? ? self : associate_objects
    
  end
  
  def serial_update(attributes)
    
    number_of_updated_objects = attributes.collect{ |attr, values| values.count }.max
    
    updated_objects = self.first(number_of_updated_objects)
    
    attributes.each_pair do |attribute, values|
      values.each_with_index do |value, index|
        updated_objects[index].update_attribute attribute, value
      end
    end
    
  end
  
  private   
  
  def random_update_n_associates(method_name, matches)            
    
    klass_eval do
    
      define_method method_name do |updated_attributes|
        
        number_of_updated_associate_objects = matches[1].to_i 
        
        self.associate = matches[2]
                              
        id_hash = {}               
        
        associate_class    
        .where( [ "#{associate_foreign_key} IN (?)", self.map(&:id) ] )
        .each do |associate_object|
          
          foreign_key_value = associate_object.send("#{associate_foreign_key}")
          id_hash[foreign_key_value] = [] if id_hash[foreign_key_value].nil?
          id_hash[foreign_key_value] << associate_object.id
          
        end               
        
        updated_associate_object_ids = []
        
        id_hash.each_pair do |key, associate_object_ids|
                    
          updated_associate_object_ids << associate_object_ids.sample(number_of_updated_associate_objects)
          
        end               
        
        associate_class.where( [" id IN (?) ", updated_associate_object_ids.flatten ] ).update_all(updated_attributes)
                                                                  
      end
    
    end
    
  end
  
  def has_n_associates(method_name, matches)
                  
    klass_eval do
      
      define_method method_name do |*args|
        
        number_of_associate_objects, self.associate = matches[1].to_i, matches[2]
                
        self.directives, self.options = split_arguments(args)              
        
        allocating_scheme = generate_allocating_scheme(number_of_associate_objects)
        
        delete_existing_associate_objects
        
        if insertion_using_import?                 
          
          create_associate_objects_by_import_using_allocating_schema allocating_scheme, self.options[:data]
          
        else                   
          
          create_associate_objects_by_factory_girl_using_allocating_schema allocating_scheme, self.options[:data]
          
        end  
              
        return_self? ? self : newly_created_associate_objects(number_of_associate_objects)
        
      end
      
    end
    
  end  
       
  def each_has_n_associates(method_name, matches)
                  
    klass_eval do
            
      define_method method_name do | *args |
                     
        number_of_associate_objects, self.associate = matches[1].to_i,  matches[2]
                
        self.directives, self.options = split_arguments(args)
                                      
        delete_existing_associate_objects
        
        if insertion_using_import?
          
          create_associate_objects_for_each_item_by_import number_of_associate_objects
                                 
        else
          
          create_associate_objects_for_each_item_by_factory_girl number_of_associate_objects      
                            
        end
                       
        return_self? ? self : newly_created_associate_objects
                
      end
      
    end
    
  end
  
  def generate_allocating_scheme(number_of_allocated_objects, number_of_receiving_objects = nil)
    
    number_of_receiving_objects = self.count if number_of_receiving_objects.nil?
    
    allocating_scheme = [number_of_allocated_objects/number_of_receiving_objects]*number_of_receiving_objects
          
    ( number_of_allocated_objects - (number_of_allocated_objects/number_of_receiving_objects)*number_of_receiving_objects ).times do
      allocating_scheme[rand(number_of_receiving_objects)] += 1
    end
    
    allocating_scheme
    
  end  
  
  def create_associate_objects_by_import_using_allocating_schema(allocating_scheme, data )
    
    data = data || []
    
    associate_objects = []
    
    data_index = 0
                            
    self.zip(allocating_scheme).each do |object, number_of_allocated_associate_objects|
            
      number_of_allocated_associate_objects.times do
                
        associate_object = FactoryGirl.build(*prepend_values_to_factory(data[data_index]))
        associate_object.send( "#{associate_foreign_key}=", object.id )
        associate_objects << associate_object
        
        data_index = data_index + 1
        
      end
      
    end                                         
    
    import_associate_objects(associate_objects)
    
  end
  
  def create_associate_objects_by_factory_girl_using_allocating_schema(allocating_scheme, data)
    
    data = data || []
    
    data_index = 0
    
    self.zip(allocating_scheme).each do |object, number_of_allocated_associate_objects|
                  
      number_of_allocated_associate_objects.times do
                
        object.send(associate) << FactoryGirl.create(*prepend_values_to_factory(data[data_index]))
        
        data_index = data_index + 1
        
      end
      
    end
    
  end
    
  def create_associate_objects_for_each_item_by_import(number_of_associate_objects)
    
    associate_objects = []
    
    self.each do |object|
            
      number_of_associate_objects.times do
        associate_object = FactoryGirl.build(*factory)
        associate_object.send( "#{associate_foreign_key}=", object.id )
        associate_objects << associate_object           
      end                  
      
    end       
    
    import_associate_objects(associate_objects)
                                                                   
  end
  
  def create_associate_objects_for_each_item_by_factory_girl(number_of_associate_objects)
    
    self.each do |object|
            
      number_of_associate_objects.times do
        
        FactoryGirl.create(*prepend_values_to_factory(associate_foreign_key.to_sym => object.id))
        
      end                  
      
    end
    
  end      
  
  def newly_created_associate_objects(number_of_associate_objects = -1)
    associate_objects = associate_class
                        .where([" #{associate_foreign_key} IN (?)", self.map(&:id) ])
                        .order("id asc")
    associate_objects.last(number_of_associate_objects) if number_of_associate_objects != -1
    associate_objects.to_a
  end  
  
  def delete_existing_associate_objects()
    associate_class.where([" #{associate_foreign_key} IN (?)", self.map(&:id) ]).destroy_all
  end          
  
  def reflection()
    self.first.class.reflections[associate.to_sym]
  end  
  
end