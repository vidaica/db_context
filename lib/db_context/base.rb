module DbContext
  
  module MethodDefiner
    
    attr_accessor :directives, :association_name, :options
    
    def self.included(klass)
      
      klass.instance_eval { alias_method :method_missing_before_db_context, :method_missing }
      
    end
    
    private
    
    def define_missing_method(method_name, definers, *args, &block)
          
      definers.each do |method_patern, defining_method|
        
        matches = method_name.to_s.match(method_patern)
        
        if matches
          self.send(defining_method, method_name, matches)
          return self.send(method_name,*args, &block) #execute the newly defined method and return the result
        end
        
      end
      
      method_missing_before_db_context(method_name, *args, &block)
      
    end      
    
    def import_activerecord_objects(klass, objects)
      
      if ! directives.include?(:skip_validation)
        
        objects.each do |obj|
          if ! obj.valid?
            raise FailedImportError, "Invalid record, error: #{obj.errors.messages.map { |key, msgs| msgs }.flatten[0]}"
          end
        end
        
      end
            
      result = klass.import objects, :validate => false
  
      if result.failed_instances.count > 0
        raise FailedImportError, "Import failed for some reason, most likely because of active record validation"
      end
      
      result
      
    end
            
    def import_associated_objects(associated_objects)
      
      import_activerecord_objects associated_class, associated_objects            
      
    end
    
    def insertion_using_import?
      ! directives.include? :girl
    end      
    
    def split_arguments(args)                
      directives = args[-1].is_a?(Hash) ? args[0...-1] : args
      options = args[-1].is_a?(Hash) ? args[-1] : {}
      [directives, options]
    end     
    
    def association_foreign_key()
      reflection.foreign_key
    end
    
    def associated_class()
      reflection.klass
    end      
    
    def factory()
      if options[:factory].nil?
        if !self.association_name.nil?
          [self.association_name.singularize.to_sym]
        else
          [self.name.underscore.to_sym]
        end
      elsif options[:factory].is_a?(Array)
        options[:factory]
      elsif options[:factory].is_a?(String) || options[:factory].is_a?(Symbol)
        [options[:factory].to_sym]
      else        
        raise TypeError, ':factory must be an Array, a String or a Symbol'
      end
    end
    
    def prepend_values_to_factory(values = {})
      values = {} if values.nil?
      fac = factory
      if fac[-1].is_a?(Hash)
        fac[-1] =  fac[-1].merge(values)
      else
        fac << values
      end
      fac
    end
    
    def return_self?
      ! (directives & [:here, :assoc]).any?
    end
    
    def klass_eval(&block)
      self.class.class_eval(&block)
    end
         
  end    

end