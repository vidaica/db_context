class Array   
       
  include DbContext::MethodDefiner
  
  def method_missing(method_name, *args, &block)
              
    definers = {
      /^belongs?_to(_[0-9a-zA-Z_]+)?$/              => 'belong_to___association_name__',
      /^makes?_([0-9a-zA-Z_]+)$/                    => 'make___association_name__',
      /^adds?_([0-9a-zA-Z_]+)$/                     => 'add___association_name__',
      /^each_has_(\d+)_([0-9a-zA-Z_]+)$/            => 'each_has_n___association_name__',
      /^(has|have)_(\d+)_([0-9a-zA-Z_]+)$/          => 'has_n___association_name__',
      /^random_update_(\d+)_([0-9a-zA-Z_]+)$/       => 'random_update_n___association_name__'
    }
    
    define_missing_method( method_name, definers, *args, &block )
        
  end  
    
  def serial_update(attributes, &block)
    
    assert_types(attributes, [Hash])
    
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
                                            
        after_method_preperation(*args, associated_objects) do
        
          self.association_name = ( ! matches[1].nil? ? matches[1].sub(/^_/,'') : associated_objects.first.class.name.underscore ).singularize
                                        
          assert_types(associated_objects, [Array, ActiveRecord::Base], "An array or an activerecord object is expected")
          
          assert_associations(:exist, :belongs_to)
          
          assert_directives([:assoc])
          
          associated_objects_array = Array(associated_objects)
                  
          return result(associated_objects) if associated_objects_array.empty?
          
          allocating_scheme = generate_allocating_scheme(self.count, associated_objects_array.count)
          
          indexes = (0...self.count).to_a
          
          associated_objects_array.zip(allocating_scheme).each do |associated_object, number_of_items|
                 
            indexes.shift(number_of_items).each do |index|
                
              if ! block.nil?
                block.call(self[index], associated_object)
                associated_object.save!(:validate => false) if associated_object.changed?
              end
              
              self[index].send("#{self.association_name}=", associated_object)
              self[index].save!(:validate => false)
              
            end
            
          end
              
          result(associated_objects)
          
        end
                      
      end
      
    end      
    
  end
  
  def make___association_name__(method_name, matches)
    
    klass_eval do
      
      define_method method_name do |*args, &block|
        
        after_method_preperation(*args, []) do
        
          self.association_name = matches[1].singularize            
          
          assert_associations(:exist, :belongs_to)
          
          assert_directives([:assoc])
          
         
          self.each do |item|
            
            attributes = FactoryGirl.attributes_for(*factory)
            block.call(item, attributes) if !block.nil?          
            item.send("#{self.association_name}=", FactoryGirl.create(*prepend_values_to_factory(attributes)))
            item.save!(:validate => false)
            
          end
          
          result(self.map{|item| item.send("#{self.association_name}")})
          
        end
        
      end
      
    end
    
  end      
  
  def add___association_name__(method_name, matches)
                  
    klass_eval do
      
      define_method method_name do |associated_objects, *args, &block|
                              
        after_method_preperation(*args, associated_objects) do
          
          self.association_name = matches[1]              
          
          assert_types(associated_objects, [Array])              
          
          assert_associations(:exist, :has_many)
          
          assert_directives([:assoc])
          
          
          allocating_scheme = generate_allocating_scheme(associated_objects.count, self.count)
          
          indexes = (0...associated_objects.count).to_a
          
          self.zip(allocating_scheme).each do |item, number_of_associated_objects|
                 
            indexes.shift(number_of_associated_objects).each do |index|
              
              if ! block.nil?
                block.call(item, associated_objects[index])
                item.save!(:validate=>false) if item.changed?
              end
              
              associated_objects[index].send("#{association_foreign_key}=", item.id)
              associated_objects[index].save!(:validate=>false)
              
            end    
            
          end
                  
          result(associated_objects)
          
        end
        
      end
      
    end
    
  end
  
  def each_has_n___association_name__(method_name, matches)
                  
    klass_eval do
            
      define_method method_name do |*args, &block|
        
        after_method_preperation(*args, []) do
                      
          number_of_associated_objects, self.association_name = matches[1].to_i,  matches[2]      
          
          assert_associations(:exist, :has_many)
          
          assert_directives([:assoc, :girl, :skip_validation])
          
          assert_no_conflict_directives([[:girl, :skip_validation]])
          
                                        
          delete_existing_associated_objects
          
          if insertion_using_import?
            
            create_associated_objects_for_each_item_by_import(number_of_associated_objects, &block)
                                   
          else
            
            create_associated_objects_for_each_item_by_factory_girl(number_of_associated_objects, &block)  
                              
          end
                         
          result newly_created_associated_objects
          
        end
                
      end
      
    end
    
  end
  
  def has_n___association_name__(method_name, matches)
                  
    klass_eval do
      
      define_method method_name do |*args, &block|
                
        after_method_preperation(*args, []) do
        
          number_of_associated_objects, self.association_name = matches[2].to_i, matches[3]              
                                
          assert_associations(:exist, :has_many)
          
          assert_directives([:assoc, :girl, :skip_validation])
          
          assert_no_conflict_directives([[:girl, :skip_validation]])
          
          
          delete_existing_associated_objects
          
          allocating_scheme = generate_allocating_scheme(number_of_associated_objects)
                      
          if insertion_using_import?                 
            
            create_associated_objects_by_import_using_allocating_schema allocating_scheme, self.options[:data], &block
            
          else                   
            
            create_associated_objects_by_factory_girl_using_allocating_schema allocating_scheme, self.options[:data], &block
            
          end  
                
          result newly_created_associated_objects(number_of_associated_objects)
          
        end
        
      end
      
    end
    
  end  
         
  def random_update_n___association_name__(method_name, matches)            
    
    klass_eval do
    
      define_method method_name do |attributes, *args, &block|
                      
        after_method_preperation(*args, []) do
        
          self.association_name = matches[2]              
          
          number_of_updated_associated_objects = matches[1].to_i
          
          assert_types(attributes, [Hash])
          
          assert_associations(:exist, :has_many)
          
          assert_directives([:assoc])
          
          
          updated_associte_objects = []
          
          self.each do |item|
                      
            item.send("#{self.association_name}").sample(number_of_updated_associated_objects).each do |updated_object|
              
              updated_object.attributes = attributes
              
              if ! block.nil?
                block.call(item, updated_object)
                item.save!(:validate => false) if item.changed?              
              end
              
              updated_object.save!(:validate => false)
                                              
              updated_associte_objects.push(updated_object)
              
            end
            
          end
                
          result updated_associte_objects
          
        end
                                                                  
      end
    
    end
    
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
           object.save!(:validate => false) if object.changed?
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
           object.save!(:validate => false) if object.changed?
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
           object.save!(:validate => false) if object.changed?
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
           object.save!(:validate => false) if object.changed?
        end
        
        FactoryGirl.create(*prepend_values_to_factory(attributes.merge(association_foreign_key.to_sym => object.id)))
        
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
  
  def assert_types(object, types, expectation_message = nil)
    expectation_message = "#{types.join(' or ')} is expected" if expectation_message.nil?
    raise TypeError, "#{expectation_message}. Received #{object.class.name}: #{object.inspect} " if ! types.any?{|type| object.is_a?(type) }
  end
  
  def assert_directives(allowed_directives)
    invalid_directives = self.directives - allowed_directives
    if invalid_directives.any?
      error_message = "Unrecognizable #{"directive".pluralize(invalid_directives.count)} received: (#{invalid_directives.map{|directive| directive.inspect}.join(',')})"
      error_message += "\nRecognizable #{"directive".pluralize(allowed_directives.count)}: (#{allowed_directives.map{|directive| directive.inspect}.join(',')})"
      raise DbContext::InvalidDirective, error_message
    end
  end
  
  def assert_no_conflict_directives(conflict_pairs)
    conflict_pairs.each do |pair|
      if (self.directives & pair) == pair
        raise DbContext::ConflictDirectives, "#{ pair.map{|directive| directive.inspect}.join(' and ') } directives can't be used together."
      end
    end
  end
  
  def result(associated_objects)
    return_self? ? self : associated_objects
  end
  
  def after_method_preperation(*args, associated_objects_to_return_if_empty)
    
    self.directives, self.options = split_arguments(args)
    
    if self.empty?
      result(associated_objects_to_return_if_empty)
    else
      yield
    end
    
  end
    
end