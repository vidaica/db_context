require File.join( File.dirname(__FILE__), '..', 'rspec_helper' )

describe ActiveRecord::Base do
  
  before :each do
    @father = FactoryGirl.create :father
  end
  
  describe 'belongs_to___association_name__ method' do
    
    before :each do      
      @child = FactoryGirl.create :child      
    end
    
    it 'delegates to Array#belongs_to___association_name__' do
            
      Array.any_instance.should_receive(:belongs_to).with([@father], :assoc).and_return([@father])
      @child.belongs_to(@father, :assoc)
      
      Array.any_instance.should_receive(:belongs_to_father).with([@father], :assoc).and_return([@father])
      @child.belongs_to_father(@father, :assoc)
      
    end
           
    it 'accepts a block and applies any changes made by the block' do
      
      @child.belongs_to_father(@father) do |child, father|
        child.name = "Child of #{father.name}"
        father.complexion = 'yellow'
      end
      
      @child.name.should eq "Child of #{@father.name}"
      @father.complexion.should eq 'yellow'
      
    end
    
     it 'returns caller with defaut parameters' do     
      @child.belongs_to(@father).should be @child
      @child.belongs_to_father(@father).should be @child
    end
    
    it 'returns associated with :assoc directive' do      
      @child.belongs_to(@father, :assoc).should be @father
      @child.belongs_to_father(@father, :assoc).should be @father
    end
          
  end
  
  describe 'makes___association_name__ method' do
    
    before :each do      
      @child = FactoryGirl.create :child      
    end
    
    it 'delegates to Array#make___association_name__' do
            
      Array.any_instance.should_receive(:makes_father).with(:assoc, :factory => [:father, :white]).and_return([])
      @child.makes_father(:assoc, :factory => [:father, :white])
     
    end
           
    it 'accepts a block and applies any changes made by the block' do
      
      @child.makes_father do |child, father_attributes|
        child.name = "Child of #{father_attributes[:name]}"
        father_attributes[:complexion] = 'yellow'
      end
      
      @child.name.should eq "Child of #{@child.father.name}"
      @child.father.complexion.should eq 'yellow'
      
    end
    
    it 'returns caller with defaut parameters' do     
      @child.makes_father.should be @child     
    end
    
    it 'returns associated with :assoc directive' do
      result = @child.makes_father(:assoc)
      result.is_a?(Father).should be true
      result.id.should eq @child.father.id
    end
    
  end
  
  describe 'adds___association_name__ method' do
    
    before :each do      
      @child = FactoryGirl.create :child      
    end
    
    it 'delegates to Array#adds___association_name__' do
            
      Array.any_instance.should_receive(:adds_children).with([@child], :assoc).and_return([@child])
      @father.adds_children([@child], :assoc)
           
    end
           
    it 'accepts a block and applies any changes made by the block' do
      
      @father.adds_children([@child]) do |father, child|
        father.complexion = 'yellow'
        child.name = "Child of #{father.name}"        
      end
      
      @father.complexion.should eq 'yellow'
      @child.name.should eq "Child of #{@father.name}"
            
    end
    
     it 'returns caller with defaut parameters' do     
      @father.adds_children([@child]).should be @father     
    end
    
    it 'returns associated with :assoc directive' do
      @children = [@child]
      @father.adds_children(@children, :assoc).should be @children
    end
    
  end
  
  describe 'has_n___association_name__ method' do
    
    before :each do      
      @child = FactoryGirl.create :child      
    end
    
    it 'delegates to Array#has_n___association_name__' do
            
      Array.any_instance.should_receive(:has_3_children).with(:assoc, :skip_validation, :factory => [:child]).and_return([@child])
      @father.has_3_children(:assoc, :skip_validation, :factory => [:child])
           
    end
           
    it 'accepts a block and applies any changes made by the block' do
      
      @father.has_3_children do |father, child_attributes|        
        father.complexion = 'yellow'
        child_attributes[:name] = "Child of #{father.name}"
      end
      
      @father.complexion.should eq 'yellow'
      @father.children.map(&:name).uniq.should eq ["Child of #{@father.name}"]     
            
    end
    
     it 'returns caller by defaut' do     
      @father.has_3_children.should be @father     
    end
    
    it 'returns newly created associated objects with :assoc directive' do    
      result = @father.has_3_children(:assoc)
      result.count.should be
      result.each do |item|
        item.is_a?(Child).should be true
      end      
    end
    
  end
  
  describe 'random_update_n___association_name__ method' do
    
    before :each do
      @father.has_4_children   
    end
       
    it 'delegates to Array.random_update_n___association_name__' do      
      Array.any_instance.should_receive(:random_update_3_children).with(name:'updated_name')
      @father.random_update_3_children(name:'updated_name')
    end 
    
    it 'updates n associated objects' do                    
      @father.random_update_2_children name:'updated_name'
      @father.children.where(:name => 'updated_name').count.should be 2      
    end
    
    it 'returns caller by defaut' do
      @father.random_update_2_children(name:'updated_name').should be @father
    end
    
    it 'returns updated associated objects with :assoc directive' do      
      result = @father.random_update_2_children({:name => 'updated_name'}, :assoc)
      result.count.should be 2
      result.map(&:id).sort.should eq @father.children.where(:name => 'updated_name').map(&:id).sort
    end
    
  end  
         
  #describe 'has___association_name__ method' do
  #  
  #  before :each do      
  #    @children_data = [{:name => 'children1'}, {:name => 'children2'}, {:name => 'children3'}]              
  #  end
  #  
  #  shared_examples_for 'a good insertion method for ActiveRecord#has___association_name__' do |insertion_method|
  #        
  #    it 'creates right number of associated objects using passed data' do      
  #      @father.has_children @children_data, insertion_method      
  #      @father.children.map(&:name).should == @children_data.map{|item| item[:name]}      
  #    end                  
  #    
  #    it 'deletes all existing associated objects of the caller' do        
  #      @father.has_children(@children_data, insertion_method).has_children(@children_data, insertion_method)
  #      @father.children.count.should be @children_data.count 
  #    end
  #    
  #    it 'does not delete existing associated objects that do not belongs to the caller' do     
  #      @another_father = FactoryGirl.create :another_father
  #      @another_father.children << FactoryGirl.build(:child)
  #      @father.has_children @children_data, insertion_method
  #      @another_father.children.count.should be 1    
  #    end            
  #    
  #    it 'does not cause associated objects getting cached' do     
  #      @father.has_children @children_data
  #      FactoryGirl.create(:child, name: 'an_extra_child').update_attribute('father_id', @father.id)
  #      @father.children.detect{|child| child.name == 'an_extra_child'}.should_not be_nil         
  #    end         
  #    
  #    it 'works with an explicit factory' do
  #      @father.has_foster_children @children_data, insertion_method, :factory => 'child'
  #      @father.foster_children.count.should be @children_data.count
  #    end
  #    
  #    it 'supports factory_girl traits' do
  #      @father.has_foster_children @children_data, insertion_method, :factory => [:child, :male]
  #      @father.foster_children.map(&:gender).uniq.should eq ['male']
  #    end
  #    
  #    it 'supports custom values in factory' do
  #      @father.has_foster_children @children_data, insertion_method, :factory => [:child, :male, gender: 'female']
  #      @father.foster_children.map(&:gender).uniq.should eq ['female']
  #    end
  #    
  #    it 'makes values in data overide values in factory' do
  #      @children_data.each{|item| item[:gender] = 'neutral'}
  #      @father.has_foster_children @children_data, insertion_method, :factory => [:child, :male, gender: 'female']
  #      @father.foster_children.map(&:gender).uniq.should eq ['neutral']
  #    end          
  #    
  #    it 'returns caller by default' do
  #      @father.has_children( @children_data, insertion_method ).should be @father      
  #    end
  #    
  #    it 'returns array of associated objects if with :assoc directive' do              
  #      returned = @father.has_children( @children_data, insertion_method, :assoc)
  #      returned.count.should be @children_data.count
  #      returned.each{|item| item.class.should be Child }
  #    end
  #    
  #    it 'raises error if factory is not an Array, String or Symbol' do        
  #      expect{@father.has_foster_children(@children_data, insertion_method, factory: {})}.to raise_exception(DbContext::InvalidFactoryType)
  #    end
  #    
  #    it 'does not raise exception if an emty array is passed' do
  #      expect{@father.has_children([])}.not_to raise_exception
  #    end
  #  
  #  end
  #        
  #  describe 'using activerecord_import for database insertion' do
  #    
  #    it 'uses activerecord_import for database insertion by default' do        
  #      @father.should_receive(:create_associated_objects_by_import)
  #      @father.has_children @children_data
  #    end
  #    
  #    it 'activates validation by default' do
  #      expect{ @father.has_children [{:name => ''}] }.to raise_exception(DbContext::FailedImportError)
  #    end
  #    
  #    it 'ignores validation with :skip_validation directive' do
  #      expect{ @father.has_children [{:name => ''}], :skip_validation }.not_to raise_exception(DbContext::FailedImportError)
  #    end
  #               
  #    it_should_behave_like 'a good insertion method for ActiveRecord#has___association_name__' 
  #    
  #  end
  #  
  #  describe 'using factory_girl for database insertion' do
  #    
  #    it 'uses factory_girl for database insertion with :girl directive' do        
  #      @father.should_receive(:create_associated_objects_by_factory_girl)
  #      @father.has_children @children_data, :girl
  #    end
  #    
  #    it_should_behave_like 'a good insertion method for ActiveRecord#has___association_name__', :girl
  #    
  #  end
  #         
  #end 
  #
  #describe 'has_n___association_name__ method' do
  #         
  #  it 'delegates to Array.has_n___association_name__' do
  #    Array.any_instance.should_receive(:has_3_children).with(:girl, :assoc, :factory => [:child, :male, :gender => 'female'], :data => [])
  #    @father.has_3_children( :girl, :assoc, :factory => [:child, :male, :gender => 'female'], :data => [] )
  #  end          
  #  
  #  it 'returns array of children with :assoc directive' do      
  #    returned = @father.has_3_children(:assoc)
  #    returned.count.should be 3
  #    returned.each{|item| item.class.should be Child }
  #  end
  #  
  #  it 'returns caller with defaut parameters' do     
  #    @father.has_3_children.should be @father      
  #  end      
  #  
  #end  
     
  #describe 'belongs_to method' do
  #  
  #  before :each do      
  #    @child = FactoryGirl.create :child      
  #  end
  #  
  #  it 'assigns the associated object to the caller' do
  #    @child.belongs_to @father
  #    @child.reload.father.id.should == @father.id
  #  end
  #  
  #  it 'works with an explicit associate' do
  #    @child.belongs_to @father, :association => 'foster_father'
  #    @child.reload.foster_father.id.should == @father.id
  #  end
  #  
  #  it 'returns the caller by default' do
  #    @child.belongs_to(@father).should be @child
  #  end
  #  
  #  it 'returns the associated object with :assoc directive' do
  #    @child.belongs_to(@father, :assoc).should be @father
  #  end
  #  
  #end
  
  #describe 'has method' do
  #  
  #  before :each do      
  #    @children = [FactoryGirl.create(:child), FactoryGirl.create(:child)]      
  #  end
  #  
  #  it 'assigns the associated objects to the caller' do
  #    @father.has @children
  #    @father.children.map(&:id).should == @children.map(&:id)
  #  end
  #  
  #  it 'works with an explicit associate' do
  #    @father.has @children, :association => 'foster_children'
  #    @father.foster_children.map(&:id).should == @children.map(&:id)
  #  end
  #  
  #  it 'returns the caller by default' do
  #    @father.has(@children).should be @father
  #  end
  #  
  #  it 'returns the the associated objects with :assoc directive' do
  #    @father.has(@children, :assoc).should be @children
  #  end
  #  
  #end
  
   
    
end