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
      children.belongs_to(@fathers, :here).should == @fathers
    end
    
    it 'returns associate objects if value of "return_what" argument is :here' do
      children.belongs_to(@fathers, :father, :here).should == @fathers
    end
                     
  end
  
  describe 'random_update_n_associates' do
    
    it 'update n associate objects' do
      @fathers.each_has_4_children
      @fathers.random_update_2_children name:'updated_name'
      @fathers.each do |level|
        level.children.where(:name => 'updated_name').count.should == 2
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
      Child.count.should be_equal(3)
    end
    
    it 'delete all existing associate objects' do
      3.times { FactoryGirl.create :child }
      @fathers.has_3_children      
      Child.count.should be_equal(3)
    end
    
    it 'assigns associate objects equally to items' do      
      @fathers.has_6_children
      @fathers.each do |level|
        level.children.count.should be_equal(2)
      end
    end
    
    it 'assigns extra associate objects randomly to items' do      
      child_counts = []
      20.times do
        @fathers.has_8_children
        @fathers.each do |level|          
          child_counts << level.children.count
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
      returned.should === @fathers
      @fathers.first.children.first.id.should_not be_nil
    end       
    
  end
  
  describe 'each_has_n_associates method' do    
    
    it 'create n associate objects for each item' do
      @fathers.each_has_3_children
      @fathers.each do |level|
        level.children.count.should be_equal(3)
      end      
    end
    
    it 'delete all existing associate objects' do      
      @fathers.each_has_3_children.each_has_3_children
      @fathers.each do |level|        
        level.children.count.should be_equal(3)
      end
    end
    
    it 'returns array of children if factory is :here' do
      assert_array_of_children @fathers.each_has_3_children(:here), 3*@fathers.size
    end       
    
    it 'returns array of children if return_what is :here' do
      assert_array_of_children @fathers.each_has_3_children(:child, :here), 3*@fathers.size
    end      
    
    it 'returns self with defaut parameters' do
      returned = @fathers.each_has_3_children
      returned.should === @fathers
    end
    
  end
    
  
  def assert_array_of_children(arr, item_count)
    arr.count.should be_equal(item_count)
    arr.each do |item|
      item.class.should == Child
    end
  end
  
    
end  