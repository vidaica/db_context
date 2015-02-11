class << ActiveRecord::Base
     
  ORDINALS = {second: 2, third: 3, fourth: 4, fifth: 5, sixth: 6, seventh: 7, eighth: 8, ninth: 9, tenth: 10}   
   
  include DbContext::MethodDefiner  
  
  def method_missing(method_name, *args, &block)      
         
    definers = {
      /^create_(\d+)$/                        => 'create_n_instances',
      /^(second|third|fourth|fifth)$/         => 'second_to_tenth_methods',
      /^(sixth|seventh|eighth|ninth|tenth)$/  => 'second_to_tenth_methods'
    }
    
    define_missing_method( method_name, definers, *args, &block )          
    
  end
  
  def one(*args)
    
    args.unshift(:girl) if ! (args & [:import, :girl]).any?
    
    self.create_1(*args).first
    
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
  
  def has(data, *args)
    
    self.directives, self.options = split_arguments(args)
       
    if insertion_using_import?
    
      create_instances_by_import(data)
    
    else
      
      create_instances_by_factory_girl(data)
      
    end
    
  end
  
  def a
    self.all.to_a
  end  
  
  private
    
  def singleton_class
    class << self; self; end
  end
  
  def second_to_tenth_methods(method_name, matches)
    
    singleton_class.class_eval do
      
      define_method method_name do
        
        order_number = ORDINALS[method_name]
        self.first(order_number).last
        
      end
      
    end
    
  end       
         
  def create_n_instances(method_name, matches)
           
    singleton_class.class_eval do
      
      define_method method_name do |*args|
        
        number_of_instances = matches[1].to_i
        
        self.directives, self.options = split_arguments(args)                        
        
        if insertion_using_import?
          
          create_instances_by_import(number_of_instances)
          
        else
          
          create_instances_by_factory_girl(number_of_instances)
          
        end              
        
      end
      
    end
    
  end
  
  def create_instances_by_import(data)
    
    instances = []
    
    data = ( data.is_a?(Fixnum) ? [{}]* data : data )
        
    data.each do |item|
      instances << FactoryGirl.build(*prepend_values_to_factory(item))
    end
    
    import_activerecord_objects(instances.first.class, instances)          
    
    instances.first.class.last(data.count)
    
  end
  
  def create_instances_by_factory_girl(data)
    
    data = ( data.is_a?(Fixnum) ? [{}]* data : data )
    
    data.map do |item|
      FactoryGirl.create(*prepend_values_to_factory(item))
    end    
    
  end 
  
end
