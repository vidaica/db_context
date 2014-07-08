class Array   
       
  include DbContext::MethodDefiner
  
  def method_missing(method_name, *args, &block)
              
    definers = {
      /^belongs?_to(_[0-9a-zA-Z_]+)?$/              => 'belong_to___association_name__',
      /^make_([0-9a-zA-Z_]+)$/                      => 'make___association_name__',
      /^add_([0-9a-zA-Z_]+)$/                       => 'add___association_name__',
      /^each_has_(\d+)_([0-9a-zA-Z_]+)$/            => 'each_has_n___association_name__',
      /^(has|have)_(\d+)_([0-9a-zA-Z_]+)$/          => 'has_n___association_name__',
      /^random_update_(\d+)_([0-9a-zA-Z_]+)$/       => 'random_update_n___association_name__'
    }
    
    define_missing_method( method_name, definers, *args, &block )
        
  end  
    
  def serial_update(attributes, &block)
    
    number_of_updated_objects = attributes.collect{ |attr, values| values.count }.max
    
    updated_objects = self.first(number_of_updated_objects)
       
    updated_objects.zip( normalize_attributes(attributes,number_of_updated_objects) ).each do |object, attr|
      
      object.update_attributes(attr)
      
      if !block.nil?
        block.call(object)
        object.save! if object.changed?
      end
      
    end        
    
    self
    
  end
  
  private
  
  def belong_to___association_name__(method_name, matches)
    
    klass_eval do
      
      define_method method_name do |associated_objects, *args, &block|
                
        associated_objects = [associated_objects] if ! associated_objects.is_a?(Array)
        
        return if associated_objects.empty?
    
        self.directives, self.options = split_arguments(args)
        
        self.association_name = ( ! matches[1].nil? ? matches[1].sub(/^_/,'') : associated_objects.first.class.name.downcase ).singularize
                
        assert_associations(:exist, :belongs_to)
        
        allocating_scheme = generate_allocating_scheme(self.count, associated_objects.count)
        
        indexes = (0...self.count).to_a
        
        associated_objects.zip(allocating_scheme).each do |associated_object, number_of_items|
               
          indexes.shift(number_of_items).each do |index|
              
            if ! block.nil?
              block.call(self[index], associated_object)
              associated_object.save! if associated_object.changed?
            end
            
            self[index].send("#{self.association_name}=", associated_object)
            self[index].save!
            
          end
          
        end
            
        return_self? ? self : associated_objects
                      
      end
      
    end      
    
  end
  
  def make___association_name__(method_name, matches)
    
    klass_eval do
      
      define_method method_name do |*args, &block|
        
        self.directives, self.options = split_arguments(args)
        
        self.association_name = matches[1].singularize
        
        assert_associations(:exist, :belongs_to)
       
        self.each do |item|
          
          attributes = FactoryGirl.attributes_for(*factory)
          block.call(item, attributes) if !block.nil?          
          item.send("#{self.association_name}=", FactoryGirl.create(*prepend_values_to_factory(attributes)))
          item.save!
          
        end
        
        return_self? ? self : self.map{|item| item.send("#{self.association_name}")}
        
      end
      
    end
    
  end      
  
  def add___association_name__(method_name, matches)
                  
    klass_eval do
      
      define_method method_name do |associated_objects, *args, &block|
        
        self.directives, self.options = split_arguments(args)
          
        self.association_name = matches[1]
        
        assert_associations(:exist, :has_many)
        
        allocating_scheme = generate_allocating_scheme(associated_objects.count, self.count)
        
        indexes = (0...associated_objects.count).to_a
        
        self.zip(allocating_scheme).each do |item, number_of_associated_objects|
               
          indexes.shift(number_of_associated_objects).each do |index|
            
            if ! block.nil?
              block.call(item, associated_objects[index])
              item.save! if item.changed?
            end
            
            associated_objects[index].send("#{association_foreign_key}=", item.id)
            associated_objects[index].save!
            
          end    
          
        end
                
        return_self? ? self : associated_objects
        
      end
      
    end
    
  end  
  
  def random_update_n___association_name__(method_name, matches)            
    
    klass_eval do
    
      define_method method_name do |updated_attributes, *args, &block|
        
        self.directives, self.options = split_arguments(args)
        
        self.association_name = matches[2]
        
        number_of_updated_associated_objects = matches[1].to_i
        
        assert_associations(:exist, :has_many)
        
        updated_associte_objects = []
        
        self.each do |item|
                    
          item.send("#{self.association_name}").sample(number_of_updated_associated_objects).each do |updated_object|
            
            updated_object.update_attributes(updated_attributes)
            
            if ! block.nil?
              block.call(item, updated_object)
              item.save! if item.changed?
              updated_object.save! if updated_object.changed?
            end
                                            
            updated_associte_objects.push(updated_object)
            
          end
          
        end
              
        return_self? ? self : updated_associte_objects
                                                                  
      end
    
    end
    
  end
  
  def has_n___association_name__(method_name, matches)
                  
    klass_eval do
      
      define_method method_name do |*args, &block|
        
        number_of_associated_objects, self.association_name = matches[2].to_i, matches[3]
                
        self.directives, self.options = split_arguments(args)
        
        assert_associations(:exist, :has_many)
        
        allocating_scheme = generate_allocating_scheme(number_of_associated_objects)
        
        delete_existing_associated_objects
        
        if insertion_using_import?                 
          
          create_associated_objects_by_import_using_allocating_schema allocating_scheme, self.options[:data], &block
          
        else                   
          
          create_associated_objects_by_factory_girl_using_allocating_schema allocating_scheme, self.options[:data], &block
          
        end  
              
        return_self? ? self : newly_created_associated_objects(number_of_associated_objects)
        
      end
      
    end
    
  end  
       
  def each_has_n___association_name__(method_name, matches)
                  
    klass_eval do
            
      define_method method_name do |*args, &block|
                      
        number_of_associated_objects, self.association_name = matches[1].to_i,  matches[2]
        
        assert_associations(:exist, :has_many)
        
        self.directives, self.options = split_arguments(args)
                                      
        delete_existing_associated_objects
        
        if insertion_using_import?
          
          create_associated_objects_for_each_item_by_import(number_of_associated_objects, &block)
                                 
        else
          
          create_associated_objects_for_each_item_by_factory_girl(number_of_associated_objects, &block)  
                            
        end
                       
        return_self? ? self : newly_created_associated_objects
                
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
  
  def create_associated_objects_by_import_using_allocating_schema(allocating_scheme, data, &block)
    
    data = data || []
    
    associated_objects = []
    
    data_index = 0
                            
    self.zip(allocating_scheme).each do |object, number_of_allocated_associated_objects|
            
      number_of_allocated_associated_objects.times do
        
        attributes = FactoryGirl.attributes_for(*prepend_values_to_factory(data[data_index]))
        
        if !block.nil?
           block.call(object, attributes)
           object.save! if object.changed?
        end
        
        attributes[:"#{association_foreign_key}"] = object.id
        
        associated_objects << FactoryGirl.build(*prepend_values_to_factory(attributes))
        
        data_index = data_index + 1
        
      end
      
    end                                         
    
    import_associated_objects(associated_objects)
    
  end
  
  def create_associated_objects_by_factory_girl_using_allocating_schema(allocating_scheme, data, &block)
    
    data = data || []
    
    data_index = 0
    
    self.zip(allocating_scheme).each do |object, number_of_allocated_associated_objects|
                  
      number_of_allocated_associated_objects.times do
        
        attributes = FactoryGirl.attributes_for(*prepend_values_to_factory(data[data_index]))
        
        if !block.nil?
           block.call(object, attributes)
           object.save! if object.changed?
        end
        
        FactoryGirl.create(*prepend_values_to_factory(attributes.merge(association_foreign_key.to_sym => object.id)))
        
        data_index = data_index + 1
        
      end
      
    end
    
  end
    
  def create_associated_objects_for_each_item_by_import(number_of_associated_objects, &block)
    
    associated_objects = []
    
    self.each do |object|
            
      number_of_associated_objects.times do
        
        attributes = FactoryGirl.attributes_for(*factory)
        
        if !block.nil?
           block.call(object, attributes)
           object.save! if object.changed?
        end
        
        attributes[:"#{association_foreign_key}"] = object.id
        
        associated_objects << FactoryGirl.build(*prepend_values_to_factory(attributes))
        
      end
      
    end
    
    import_associated_objects(associated_objects)
                                                                   
  end
  
  def create_associated_objects_for_each_item_by_factory_girl(number_of_associated_objects, &block)
    
    self.each do |object|
            
      number_of_associated_objects.times do
        
        attributes = FactoryGirl.attributes_for(*factory)
        
        if !block.nil?
           block.call(object, attributes)
           object.save! if object.changed?
        end
        
        FactoryGirl.create(*prepend_values_to_factory(attributes.merge(association_foreign_key.to_sym => object.id)))
        
      end                  
      
    end
    
  end      
  
  def newly_created_associated_objects(number_of_associated_objects = -1)
    associated_objects = associated_class
                        .where([" #{association_foreign_key} IN (?)", self.map(&:id) ])
                        .order("id asc")
    associated_objects.last(number_of_associated_objects) if number_of_associated_objects != -1
    associated_objects.to_a
  end  
  
  def delete_existing_associated_objects()
    associated_class.where([" #{association_foreign_key} IN (?)", self.map(&:id) ]).destroy_all
  end          
  
  def reflection()
    self.first.class.reflections[self.association_name.to_sym]
  end
  
  def normalize_attributes(serial_attributes, number_of_updated_objects)
       
    normalized_attributes = number_of_updated_objects.times.map{{}}
    
    serial_attributes.each_pair do |attribute, values|   
      values.each_with_index do |value, index|       
        normalized_attributes[index][attribute] = value        
      end
    end
    
    normalized_attributes
    
  end
  
  def assert_associations(*association_types)
    
    association_types.each do |type|
      
      case type
        
      when :exist;        assert_association_exist        
      when :has_many;     assert_has_many_association        
      when :belongs_to;   assert_belongs_to_association
      end
      
    end
    
  end
  
  def assert_association_exist
    raise DbContext::NonExistentAssociation, ":#{self.association_name} association does not exist in #{self.first.class}" if reflection.nil?
  end
  
  def assert_has_many_association
    raise DbContext::HasManyAssociationExpected, "A has_many association is expected. :#{self.association_name} is not a has_many association, it is a #{reflection.macro} association" if reflection.macro != :has_many
  end
    
  def assert_belongs_to_association
    raise DbContext::BelongsToAssociationExpected, "A belongs_to association is expected. :#{self.association_name} is not a belongs_to association, it is a #{reflection.macro} association" if reflection.macro != :belongs_to
  end
  
  
end