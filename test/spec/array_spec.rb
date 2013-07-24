require File.join( File.dirname(__FILE__), '..', 'rspec_helper' )

describe Array do
    
  before :each do
    @fathers = Father.create_3
  end
  
  describe 'belongs_to' do
         
    let(:children){ 3.Children }
    
    it 'connects object with associate objects' do        
      children.belongs_to @fathers
      children.map{|child| child.father.id }.should == @fathers.map(&:id)
    end
    
    it 'returns associate objects if value of "associate_name" argument is :here' do
      children.belongs_to(@fathers, :here).should be @fathers
    end
    
    it 'returns associate objects if value of "return_what" argument is :here' do
      children.belongs_to(@fathers, :father, :here).should be @fathers
    end
                     
  end
  
  describe 'random_update_n_associates' do
    
    it 'update n associate objects' do
      @fathers.each_has_4_children
      @fathers.random_update_2_children name:'updated_name'
      @fathers.each do |father|
        father.children.where(:name => 'updated_name').count.should be 2
      end
    end
    
    it 'update n associate objects randomly' do
      
      @fathers = [ @fathers.first ]
      
      updated_indexes = []
            
      10.times do        
        @fathers.each_has_4_children
        @fathers.random_update_2_children(name:'updated_name')
        @fathers.first.children.order('id asc').each_with_index do |child, index|
          updated_indexes << index if child.name == 'updated_name'
        end
      end      
      
      updated_indexes.flatten.uniq.sort.should == [0,1,2,3]
      
    end
    
  end
  
  describe 'has_n_associates method' do      
           
    it 'creates n associate objects' do
      @fathers.has_3_children
      Child.count.should be 3
    end
    
    it 'delete all existing associate objects' do
      3.times { FactoryGirl.create :child }
      @fathers.has_3_children      
      Child.count.should be 3
    end
    
    it 'assigns associate objects equally to items' do      
      @fathers.has_6_children
      @fathers.each do |father|
        father.children.count.should be 2
      end
    end
    
    it 'assigns extra associate objects randomly to items' do      
      child_counts = []
      20.times do
        @fathers.has_8_children
        @fathers.each do |father|          
          child_counts << father.children.count
        end        
      end      
      child_counts.uniq.sort.should == [2,3,4]
    end
    
    it 'does not cause associate objects getting cached' do      
      @father = Father.one
      [@father].has_3_children
      (FactoryGirl.create :child, name:'outlaw child', father_id: @father.id)
      @father.children.detect{|child| child.name == 'outlaw child' }.should_not be_nil
    end
    
    it 'returns array of children if factory is :here' do
      assert_array_of_children @fathers.has_3_children(:here), 3     
    end
    
    it 'returns array of children if return_what is :here' do
      assert_array_of_children @fathers.has_3_children(:child, :here), 3
    end      
    
    it 'returns self with defaut parameters' do     
      returned = @fathers.has_3_children
      returned.should be @fathers
      @fathers.first.children.first.id.should_not be_nil
    end       
    
  end   
  
  describe 'each_has_n_associates method' do    
    
    describe 'using activerecord_import for database insertion' do
      
      it 'uses activerecord_import for database insertion by default' do        
        @fathers.should_receive(:create_associate_objects_for_each_item_by_import)
        @fathers.each_has_3_children        
      end
       
      it 'creates n associate objects for each item of array' do
        @fathers.each_has_3_children
        @fathers.each do |father|
          father.children.count.should be 3
        end      
      end
      
      it 'activates validation by default' do
        expect{ @fathers.each_has_3_children :factory => :invalid_child }.to raise_exception(FailedImportError)
      end
      
      it 'ignores validation with :skip_validation directive' do
        expect{ @fathers.each_has_3_children :skip_validation, :factory => :invalid_child }.not_to raise_exception(FailedImportError)
      end
                 
    end
        
    describe 'using factory_girl for database insertion' do
      
      it 'uses factory_girl for database insertion with :girl directive' do        
        @fathers.should_receive(:create_associate_objects_for_each_item_by_factory_girl)
        @fathers.each_has_3_children :girl
      end
       
      it 'creates n associate objects for each item of array' do
        @fathers.each_has_3_children :girl
        @fathers.each do |father|
          father.children.count.should be 3
        end      
      end           
      
    end     
    
    it 'works with passed factory' do 
      @fathers.each_has_3_children :factory => :another_child
      @fathers.map{|father| father.children.map(&:name) }.flatten.uniq == ['Another Child']
    end
    
    it 'deletes all existing associate objects' do
      @fathers.each_has_3_children.each_has_3_children
      @fathers.each do |father|        
        father.children.count.should be 3
      end
    end
                   
    it 'returns self by defaut' do
      returned = @fathers.each_has_3_children
      returned.should be @fathers
    end
    
    it 'returns array of associate objects with :next directive' do
      assert_array_of_children @fathers.each_has_3_children(:next), 3*@fathers.size
    end
                     
  end
    
  
  def assert_array_of_children(arr, item_count)
    arr.count.should be item_count
    arr.each do |item|
      item.class.should be Child
    end
  end
      
end  