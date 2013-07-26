module DbContext
  
  module MethodDefiner
    
    attr_accessor :directives, :associate, :options
    
    def self.included(klass)
      
      klass.instance_eval { alias_method :method_missing_before_db_context, :method_missing }
      
    end
    
    def define_missing_method(method_name, definers, *args, &block)
          
      definers.each do |method_patern, defining_method|
        
        matches = method_name.to_s.match(method_patern)
        
        if matches
          self.send(defining_method, method_name, matches)
          return self.send(method_name,*args) #execute the newly defined method and return the result
        end
        
      end
      
      method_missing_before_db_context(method_name, *args, &block)
      
    end
    
    private
            
    def import_associate_objects(associate_objects)
    
      result = associate_class.import associate_objects, :validate => ! directives.include?(:skip_validation)                             
  
      if result.failed_instances.count > 0
        raise FailedImportError, "Import failed for some reason, most likely because of active record validation"
      end
      
    end
    
    def insertion_using_import?
      ! directives.include? :girl
    end
    
    def split_arguments(args)                
      directives = args[-1].is_a?(Hash) ? args[0...-1] : args
      options = args[-1].is_a?(Hash) ? args[-1] : {}
      [directives, options]
    end 
    
    def split_arguments(args)                
      directives = args[-1].is_a?(Hash) ? args[0...-1] : args
      options = args[-1].is_a?(Hash) ? args[-1] : {}
      [directives, options]
    end     
    
    def associate_foreign_key()
      reflection.foreign_key
    end
    
    def associate_class()
      reflection.klass
    end          
    
    def factory()
      ( options[:factory].nil? ? associate.singularize : options[:factory] ).to_sym
    end
    
    def return_self?
      ! (directives & [:here, :next]).any?
    end
         
  end

end