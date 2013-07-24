class ActiveRecord::Base
     
  ORDINALS = {second: 2, third: 3, fourth: 4, fifth: 5, sixth: 6, seventh: 7, eighth: 8, ninth: 9, tenth: 10}   
  
  class << self
           
    include DbContext::MethodDefiner  
    
    def method_missing(method_name, *args, &block)      
           
      definers = {
        /^create_(\d+)$/                        => 'define_create_n_instances',
        /^(second|third|fourth|fifth)$/         => 'define_second_to_tenth_methods',
        /^(sixth|seventh|eighth|ninth|tenth)$/  => 'define_second_to_tenth_methods'
      }
      
      define_missing_method( method_name, definers, *args, &block )          
      
    end
    
    def one(method = :factory, factory = nil, import_options = {})
      self.create_1(method, factory, import_options).first
    end
    
    def serial_update(attributes)
      
      number_of_updated_objects = attributes.collect{ |attr, values| values.count }.max
      
      objects = self.order('id asc').first(number_of_updated_objects)
      
      attributes.each_pair do |attribute, values|
        values.each_with_index do |value, index|
          objects[index].update_attribute attribute, value
        end
      end
      
    end
    
    def has(data, factory = nil, import_options = {})
      factory = factory.nil? ? self.name.underscore.to_sym : factory 
      create_instances_by_import(data, factory, import_options)
    end
    
    private
    
    def singleton_class
      class << self; self; end
    end
    
    def define_second_to_tenth_methods(method_name, matches)
      
      singleton_class.class_eval do
        
        define_method method_name do
          
          order_number = ORDINALS[method_name]
          self.first(order_number).last
          
        end
        
      end
      
    end       
           
    def define_create_n_instances(method_name, matches)
      
      number_of_instances = matches[1].to_i
      
      singleton_class.class_eval do
        
        define_method method_name do |create_method = :import, factory = nil, import_options = {}|
                   
          factory = factory.nil? ? self.name.underscore.to_sym : factory         
          
          if create_method == :import
            
            create_instances_by_import(number_of_instances, factory, import_options)
            
          elsif create_method == :factory
            
            create_instances_by_factory(number_of_instances,factory)
            
          else
            
            raise InvalidCreateMethod, 'invalid create_method, valid methods are :import and :factory'
            
          end
          
        end
        
      end
      
    end
    
    def create_instances_by_import(data, factory, options)
      
      instances = []
      
      data = ( data.class == Fixnum ? [{}]* data : data )
          
      data.each do |item|
        instances << FactoryGirl.build( factory, item )
      end  
            
      result = instances.first.class.import instances, options
      
      if result.failed_instances.count > 0
        raise FailedImportError, "Import failed for some reason, most likely because of active record validation"
      end
      
      instances.first.class.last(data.count)
      
    end
    
    def create_instances_by_factory(number_of_instances, factory)
      
      number_of_instances.times.map do
        FactoryGirl.create factory
      end
      
    end
  
  end  
  
end