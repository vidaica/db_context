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
      
      @child.reload.name.should eq "Child of #{@father.name}"
      @father.reload.complexion.should eq 'yellow'
      
    end
    
     it 'returns caller by defaut' do     
      @child.belongs_to(@father).should be @child
      @child.belongs_to_father(@father).should be @child
    end
    
    it 'returns associated objects with :assoc directive' do      
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
      
      @child.reload.name.should eq "Child of #{@child.father.name}"
      @child.reload.father.complexion.should eq 'yellow'
      
    end
    
    it 'returns caller by defaut' do     
      @child.makes_father.should be @child     
    end
    
    it 'returns newly created associated object with :assoc directive' do
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
      
      @father.reload.complexion.should eq 'yellow'
      @child.reload.name.should eq "Child of #{@father.name}"
            
    end
    
     it 'returns caller by defaut' do     
      @father.adds_children([@child]).should be @father     
    end
    
    it 'returns associated objects with :assoc directive' do
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
      
      @father.reload.complexion.should eq 'yellow'
      @father.reload.children.map(&:name).uniq.should eq ["Child of #{@father.name}"]     
            
    end
    
     it 'returns caller by default' do     
      @father.has_3_children.should be @father     
    end
    
    it 'returns newly created associated objects with :assoc directive' do    
      result = @father.has_3_children(:assoc)
      assert_array_of(result, 3, Child)      
    end
    
  end
  
  describe 'has___association_name__ method' do
    
    before :each do      
       @children_data = [{:name => 'children1'}, {:name => 'children2'}, {:name => 'children3'}]   
    end
    
    it 'delegates to Array#has_n___association_name__' do
            
      Array.any_instance.should_receive(:has_3_children)
      .with(
            :assoc,
            :skip_validation,
            :factory => [:child],
            :data => @children_data
          )
      .and_return([@child])
      
      @father.has_children(@children_data, :assoc, :skip_validation, :factory => [:child])
           
    end
           
    it 'accepts a block and applies any changes made by the block' do
      
      @father.has_children(@children_data) do |father, child_attributes|        
        father.complexion = 'yellow'
        child_attributes[:name] = "Child of #{father.name}"
      end
      
      @father.reload.complexion.should eq 'yellow'
      @father.reload.children.map(&:name).uniq.should eq ["Child of #{@father.name}"]     
            
    end
    
     it 'returns caller by default' do     
      @father.has_children(@children_data).should be @father
    end
    
    it 'returns newly created associated objects with :assoc directive' do    
      result = @father.has_children(@children_data, :assoc)
      assert_array_of(result, 3, Child)     
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
    
    it 'accepts a block and applies any changes made by the block' do
            
      @father.random_update_2_children name:'updated_name' do |father, updated_child|        
        father.name = 'Ben'        
        updated_child.gender = "neutral"        
      end
                     
      @father.reload.name.should eq 'Ben'  
      @father.children.each do |child|
        child.reload.gender.should eq "neutral" if child.name == 'updated_name'
      end        
        
    end
    
    it 'returns caller by default' do
      @father.random_update_2_children(name:'updated_name').should be @father
    end
    
    it 'returns updated associated objects with :assoc directive' do      
      result = @father.random_update_2_children({:name => 'updated_name'}, :assoc)
      assert_array_of(result, 2, Child)
      result.map(&:id).sort.should eq @father.children.where(:name => 'updated_name').map(&:id).sort
    end
    
  end  
           
end