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
            
      expect_any_instance_of(Array).to receive(:belongs_to).with([@father], :assoc).and_return([@father])
      @child.belongs_to(@father, :assoc)
      
      expect_any_instance_of(Array).to receive(:belongs_to_father).with([@father], :assoc).and_return([@father])
      @child.belongs_to_father(@father, :assoc)
      
    end
           
    it 'accepts a block and applies any changes made by the block' do
      
      @child.belongs_to_father(@father) do |child, father|
        child.name = "Child of #{father.name}"
        father.complexion = 'yellow'
      end
      
      expect(@child.reload.name).to eq "Child of #{@father.name}"
      expect(@father.reload.complexion).to eq 'yellow'
      
    end
    
     it 'returns caller by defaut' do     
      expect(@child.belongs_to(@father)).to be @child
      expect(@child.belongs_to_father(@father)).to be @child
    end
    
    it 'returns associated objects with :assoc directive' do      
      expect(@child.belongs_to(@father, :assoc)).to be @father
      expect(@child.belongs_to_father(@father, :assoc)).to be @father
    end
          
  end
  
  describe 'makes___association_name__ method' do
    
    before :each do      
      @child = FactoryGirl.create :child      
    end
    
    it 'delegates to Array#make___association_name__' do
            
      expect_any_instance_of(Array).to receive(:makes_father).with(:assoc, :factory => [:father, :white]).and_return([])
      @child.makes_father(:assoc, :factory => [:father, :white])
     
    end
           
    it 'accepts a block and applies any changes made by the block' do
      
      @child.makes_father do |child, father_attributes|
        child.name = "Child of #{father_attributes[:name]}"
        father_attributes[:complexion] = 'yellow'
      end
      
      expect(@child.reload.name).to eq "Child of #{@child.father.name}"
      expect(@child.reload.father.complexion).to eq 'yellow'
      
    end
    
    it 'returns caller by defaut' do     
      expect(@child.makes_father).to be @child     
    end
    
    it 'returns newly created associated object with :assoc directive' do
      result = @child.makes_father(:assoc)
      expect(result.is_a?(Father)).to be true
      expect(result.id).to eq @child.father.id
    end
    
  end
  
  describe 'adds___association_name__ method' do
    
    before :each do      
      @child = FactoryGirl.create :child      
    end
    
    it 'delegates to Array#adds___association_name__' do
            
      expect_any_instance_of(Array).to receive(:adds_children).with([@child], :assoc).and_return([@child])
      @father.adds_children([@child], :assoc)
           
    end
           
    it 'accepts a block and applies any changes made by the block' do
      
      @father.adds_children([@child]) do |father, child|
        father.complexion = 'yellow'
        child.name = "Child of #{father.name}"        
      end
      
      expect(@father.reload.complexion).to eq 'yellow'
      expect(@child.reload.name).to eq "Child of #{@father.name}"
            
    end
    
    it 'returns caller by defaut' do     
      expect(@father.adds_children([@child])).to be @father     
    end
    
    it 'returns associated objects with :assoc directive' do
      @children = [@child]
      expect(@father.adds_children(@children, :assoc)).to be @children
    end
    
  end
  
  describe 'has_n___association_name__ method' do
    
    before :each do      
      @child = FactoryGirl.create :child      
    end
    
    it 'delegates to Array#has_n___association_name__' do
            
      expect_any_instance_of(Array).to receive(:has_3_children).with(:assoc, :skip_validation, :factory => [:child]).and_return([@child])
      @father.has_3_children(:assoc, :skip_validation, :factory => [:child])
           
    end
           
    it 'accepts a block and applies any changes made by the block' do
      
      @father.has_3_children do |father, child_attributes|        
        father.complexion = 'yellow'
        child_attributes[:name] = "Child of #{father.name}"
      end
      
      expect(@father.reload.complexion).to eq 'yellow'
      expect(@father.reload.children.map(&:name).uniq).to eq ["Child of #{@father.name}"]     
            
    end
    
    it 'returns caller by default' do     
      expect(@father.has_3_children).to be @father     
    end
    
    it 'returns newly created associated objects with :assoc directive' do    
      expect(@father.has_3_children(:assoc)).to be_an_array_of(Child).with(3).items      
    end
    
  end
  
  describe 'has___association_name__ method' do
    
    before :each do      
       @children_data = [{:name => 'children1'}, {:name => 'children2'}, {:name => 'children3'}]   
    end
    
    it 'delegates to Array#has_n___association_name__' do
            
      expect_any_instance_of(Array).to receive(:has_3_children)
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
      
      expect(@father.reload.complexion).to eq 'yellow'
      expect(@father.reload.children.map(&:name).uniq).to eq ["Child of #{@father.name}"]     
            
    end
    
    it 'returns caller by default' do     
      expect(@father.has_children(@children_data)).to be @father
    end
    
    it 'returns newly created associated objects with :assoc directive' do    
      expect(@father.has_children(@children_data, :assoc)).to be_an_array_of(Child).with(3).items     
    end
    
  end
  
  describe 'random_update_n___association_name__ method' do
    
    before :each do
      @father.has_4_children   
    end
       
    it 'delegates to Array.random_update_n___association_name__' do      
      expect_any_instance_of(Array).to receive(:random_update_3_children).with(name:'updated_name')
      @father.random_update_3_children(name:'updated_name')
    end 
    
    it 'accepts a block and applies any changes made by the block' do
            
      @father.random_update_2_children name:'updated_name' do |father, updated_child|        
        father.name = 'Ben'        
        updated_child.gender = "neutral"        
      end
                     
      expect(@father.reload.name).to eq 'Ben'  
      @father.children.each do |child|
        expect(child.reload.gender).to eq "neutral" if child.name == 'updated_name'
      end        
        
    end
    
    it 'returns caller by default' do
      expect(@father.random_update_2_children(name:'updated_name')).to be @father
    end
    
    it 'returns updated associated objects with :assoc directive' do      
      result = @father.random_update_2_children({:name => 'updated_name'}, :assoc)
      expect(result).to be_an_array_of(Child).with(2).items
      expect(result.map(&:id).sort).to eq @father.children.where(:name => 'updated_name').map(&:id).sort
    end
    
  end  
           
end