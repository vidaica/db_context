class Array   
       
  include DbContext::MethodDefiner
  
  def method_missing(method_name, *args, &block)
              
    definers = {
      /^belongs?_to_([0-9a-zA-Z_]+)$/               => 'belong_to_associates',
      /^make_([0-9a-zA-Z_]+)$/                      => 'make_associates',
      /^add_([0-9a-zA-Z_]+)$/                       => 'add_associates',
      /^each_has_(\d+)_([0-9a-zA-Z_]+)$/            => 'each_has_n_associates',
      /^(has|have)_(\d+)_([0-9a-zA-Z_]+)$/          => 'has_n_associates',
      /^random_update_(\d+)_([0-9a-zA-Z_]+)$/       => 'random_update_n_associates'
    }
    
    define_missing_method( method_name, definers, *args, &block )
        
  end
  
  def belong_to(associate_objects, *args)            
    associate = ( associate_objects.is_a?(Array) ? associate_objects.first :  associate_objects).class.name.downcase    
    self.send("belong_to_#{associate.pluralize}", associate_objects, *args)
  end
  
  alias_method :belongs_to, :belong_to
    
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
  
  def belong_to_associates(method_name, matches)
    
    klass_eval do
      
      define_method method_name do |associate_objects, *args|
                
        associate_objects = [associate_objects] if ! associate_objects.is_a?(Array)
        
        return if associate_objects.empty?
    
        self.directives, self.options = split_arguments(args)
        
        self.associate = matches[1].singularize
        
        assert_relationships(:exist, :belongs_to)
        
        allocating_scheme = generate_allocating_scheme(self.count, associate_objects.count)
        
        indexes = (0...self.count).to_a
        
        associate_objects.zip(allocating_scheme).each do |associate_object, number_of_items|
               
          indexes.shift(number_of_items).each do |index|
                        
            self[index].send("#{associate}=", associate_object)
            self[index].save!
            
          end
          
        end
            
        return_self? ? self : associate_objects
                      
      end
      
    end      
    
  end
  
  def make_associates(method_name, matches)
    
    klass_eval do
      
      define_method method_name do |*args, &block|
        
        self.directives, self.options = split_arguments(args)
        
        self.associate = matches[1].singularize
        
        assert_relationships(:exist, :belongs_to)
       
        self.each do |item|
          
          attributes = FactoryGirl.attributes_for(*factory)
          block.call(item, attributes) if !block.nil?          
          item.send("#{associate}=", FactoryGirl.create(*prepend_values_to_factory(attributes)))
          item.save
          
        end
        
        return_self? ? self : self.map{|item| item.send("#{associate}")}
        
      end
      
    end
    
  end      
  
  def add_associates(method_name, matches)
                  
    klass_eval do
      
      define_method method_name do |associate_objects, *args, &block|
        
        self.directives, self.options = split_arguments(args)
          
        self.associate = matches[1]
        
        assert_relationships(:exist, :has_many)
        
        allocating_scheme = generate_allocating_scheme(associate_objects.count, self.count)
        
        indexes = (0...associate_objects.count).to_a
        
        self.zip(allocating_scheme).each do |item, number_of_associate_objects|
               
          indexes.shift(number_of_associate_objects).each do |index|
            
            if ! block.nil?
              block.call(item, associate_objects[index])
              item.save! if item.changed?
            end
            
            associate_objects[index].send("#{associate_foreign_key}=", item.id)
            associate_objects[index].save!
            
          end    
          
        end
                
        return_self? ? self : associate_objects
        
      end
      
    end
    
  end  
  
  def random_update_n_associates(method_name, matches)            
    
    klass_eval do
    
      define_method method_name do |updated_attributes|
        
        self.associate = matches[2]
        
        number_of_updated_associate_objects = matches[1].to_i
        
        assert_relationships(:exist, :has_many)
                                            
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
        
        number_of_associate_objects, self.associate = matches[2].to_i, matches[3]
                
        self.directives, self.options = split_arguments(args)
        
        assert_relationships(:exist, :has_many)
        
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
            
      define_method method_name do |*args, &block|
                      
        number_of_associate_objects, self.associate = matches[1].to_i,  matches[2]
        
        assert_relationships(:exist, :has_many)
        
        self.directives, self.options = split_arguments(args)
                                      
        delete_existing_associate_objects
        
        if insertion_using_import?
          
          create_associate_objects_for_each_item_by_import(number_of_associate_objects, &block)
                                 
        else
          
          create_associate_objects_for_each_item_by_factory_girl(number_of_associate_objects, &block)  
                            
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
    
  def create_associate_objects_for_each_item_by_import(number_of_associate_objects, &block)
    
    associate_objects = []
    
    self.each do |object|
            
      number_of_associate_objects.times do
        attributes = FactoryGirl.attributes_for(*factory)       
        block.call(object, attributes) if !block.nil?
        attributes[:"#{associate_foreign_key}"] = object.id
        associate_objects << FactoryGirl.build(*prepend_values_to_factory(attributes))
      end
      
    end
    
    import_associate_objects(associate_objects)
                                                                   
  end
  
  def create_associate_objects_for_each_item_by_factory_girl(number_of_associate_objects, &block)
    
    self.each do |object|
            
      number_of_associate_objects.times do              
        attributes = FactoryGirl.attributes_for(*factory)  
        block.call(object, attributes) if !block.nil?
        FactoryGirl.create(*prepend_values_to_factory(attributes.merge(associate_foreign_key.to_sym => object.id)))
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
  
  def assert_relationships(*relationships)
    relationships.each do |relationship|
      case relationship
      when :exist
        assert_relationship_exist
      when :has_many
        assert_has_many_relationship
      when :belongs_to
        assert_belongs_to_relationship
      end
    end
  end
  
  def assert_relationship_exist
    raise DbContext::NonExistentRelationship, ":#{associate} association does not exist in #{self.first.class}" if reflection.nil?
  end
  
  def assert_has_many_relationship
    raise DbContext::HasManyRelationshipExpected, "A has_many relationship is expected. :#{associate} is not a has_many relationship, it is a #{reflection.macro} relationship" if reflection.macro != :has_many
  end
    
  def assert_belongs_to_relationship
    raise DbContext::BelongsToRelationshipExpected, "A belongs_to relationship is expected. :#{associate} is not a belongs_to relationship, it is a #{reflection.macro} relationship" if reflection.macro != :belongs_to
  end
  
  
end