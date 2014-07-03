require File.join( File.dirname(__FILE__), '..', 'rspec_helper' )

describe Array do
    
  before :each do
    @fathers = 3.times.map{ FactoryGirl.create :father }
  end
  
  describe 'belongs_to' do
    
    before :each do
      @children = 3.times.map{ FactoryGirl.create :child }    
    end
    
    it 'connects object with associate objects' do        
      @children.belongs_to @fathers
      @children.map{|child| child.father.id }.should == @fathers.map(&:id)
    end       
    
    it 'works with an explicit associate' do
      @children.belongs_to @fathers, :associate => :foster_father
      @children.map{|child| child.foster_father.id }.should == @fathers.map(&:id)
    end
     
    it 'returns caller by default' do
      @children.belongs_to(@fathers).should be @children
    end
    
    it 'returns associate objects with :next directive' do
      @children.belongs_to(@fathers, :next).should be @fathers
    end
    
    it 'allocates items equally to associate objects' do
      @children = @children + 3.times.map{ FactoryGirl.create :child }
      @children.belongs_to @fathers
      @fathers.each {|father| father.children.count.should be @children.count/@fathers.count  }
    end
    
    it 'allocates extra objects randomly if the number of items does not equal to the number of associate objects' do
      @children << FactoryGirl.create(:child)
      extra_child_assigned_at_indexes = []
      100.times do
        @children.belongs_to(@fathers)
        @fathers.each_with_index do |father, index|
          extra_child_assigned_at_indexes << index if father.children.count == 2
        end
      end
      extra_child_assigned_at_indexes.uniq.sort.should eq [0,1,2]
    end
    
    it 'accepts a single associate object' do
      one_father = @fathers.first
      @children.belongs_to one_father
      one_father.children.map(&:id).sort.should eq @children.map(&:id).sort
    end
                     
  end
  
  describe 'random_update_n_associates' do
    
    it 'updates n associate objects' do
      @fathers.each_has_4_children
      @fathers.random_update_2_children name:'updated_name'
      @fathers.each do |father|
        father.children.where(:name => 'updated_name').count.should be 2
      end
    end
    
    it 'updates n associate objects randomly' do
      
      @fathers = [ @fathers.first ]
      
      updated_indexes = []
            
      100.times do        
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
    
    shared_examples_for 'a good insertion method for Array#has_n_associates' do |insertion_method|
    
      it 'creates n associate objects for all items of the caller' do      
        @fathers.has_5_children insertion_method
        @fathers.sum{|father| father.children.count }.should be 5      
      end                   
      
      it 'deletes all existing associate objects of items in the caller' do      
        @fathers.has_5_children.has_3_children insertion_method
        @fathers.sum{|father| father.children.count }.should be 3      
      end
      
      it 'does not delete existing associate objects that do not belongs to items in the caller' do     
        @another_father = FactoryGirl.create :another_father
        @another_father.children << FactoryGirl.build(:child)
        @fathers.has_3_children insertion_method
        @another_father.children.count.should be 1      
      end  
      
      it 'assigns associate objects equally to items' do
        @fathers.has_6_children insertion_method
        @fathers.each do |father|
          father.children.count.should be 2
        end
      end
      
      it 'assigns extra associate objects randomly to items' do     
        child_counts = []
        100.times do
          @fathers.has_8_children insertion_method
          @fathers.each do |father|          
            child_counts << father.children.count
          end        
        end      
        child_counts.uniq.sort.should == [2,3,4]      
      end
      
      it 'does not cause associate objects getting cached' do     
        @father = FactoryGirl.create :father
        [@father].has_3_children insertion_method
        (FactoryGirl.create :child, name:'outlaw child', father_id: @father.id)
        @father.children.detect{|child| child.name == 'outlaw child' }.should_not be_nil      
      end
      
      it 'works with provided data do' do
        
        @fathers.has_3_children( insertion_method, data: [ {name: 'Ti' }, {name: 'Teo'} ] )
        child1 = @fathers[0].children.first
        child2 = @fathers[1].children.first
        child1.name.should eq 'Ti'
        child2.name.should eq 'Teo'
        
      end
      
      it 'works with an explicit factory' do      
        @fathers.has_5_foster_children insertion_method, :factory => :child
        @fathers.sum{|father| father.foster_children.count }.should be 5
      end
      
      it 'supports factory_girl traits' do
        @fathers.has_5_foster_children insertion_method, :factory => [:child, :male]
        @fathers.map { |father| father.foster_children.map(&:gender) }.flatten.uniq.should eq ['male'] 
      end
      
      it 'supports attribute values in factory' do
        @fathers.has_5_foster_children insertion_method, :factory => [:child, :male, :gender => 'female']
        @fathers.map { |father| father.foster_children.map(&:gender) }.flatten.uniq.should eq ['female']
      end
      
      it 'makes values in options[:data] overide values in factory' do        
        @fathers.has_5_foster_children insertion_method, :factory => [:child, :male, :gender => 'female'], :data => [{:gender => 'neutral'}]*5
        @fathers.map { |father| father.foster_children.map(&:gender) }.flatten.uniq.should eq ['neutral']
      end
      
      it 'returns caller by default' do      
        @fathers.has_3_children(insertion_method).should be @fathers      
      end
      
      it 'returns array of associate objects if with :next directive' do      
        assert_array_of_children @fathers.has_3_children(insertion_method, :next), 3      
      end
    
    end
  
    describe 'using activerecord_import for database insertion' do
      
      it 'uses activerecord_import for database insertion by default' do        
        @fathers.should_receive(:create_associate_objects_by_import_using_allocating_schema)
        @fathers.has_3_children
      end           
      
      it 'activates validation by default' do
        expect{ @fathers.has_3_children :factory => :invalid_child }.to raise_exception(DbContext::FailedImportError)
      end
      
      it 'ignores validation with :skip_validation directive' do
        expect{ @fathers.has_3_children :skip_validation, :factory => :invalid_child }.not_to raise_exception(DbContext::FailedImportError)
      end
      
      it_should_behave_like 'a good insertion method for Array#has_n_associates'
      
    end
    
    describe 'using factory_girl for database insertion' do
      
      it 'uses factory_girl for database insertion with :girl directive' do        
        @fathers.should_receive(:create_associate_objects_by_factory_girl_using_allocating_schema)
        @fathers.has_3_children :girl
      end
      
      it_should_behave_like 'a good insertion method for Array#has_n_associates', :girl
      
    end  
    
  end
   
  
  describe 'each_has_n_associates method' do             
    
    shared_examples_for 'a good insertion method for Array#each_has_n_associates' do |insertion_method|
    
      it 'creates n associate objects for each item of array' do      
        @fathers.each_has_3_children insertion_method
        @fathers.each do |father|
          father.children.count.should be 3
        end      
      end
      
      it 'works with an explicit factory' do      
        @fathers.each_has_3_foster_children insertion_method, :factory => :child
        @fathers.each do |father|        
          father.foster_children.count.should be 3
        end
      end
      
      it 'supports factory_girl traits' do
        @fathers.each_has_3_foster_children insertion_method, :factory => [:child, :male]
        @fathers.map { |father| father.foster_children.map(&:gender) }.flatten.uniq.should eq ['male'] 
      end
      
      it 'supports attribute values in factory' do
        @fathers.each_has_3_foster_children insertion_method, :factory => [:child, :male, :gender => 'female']
        @fathers.map { |father| father.foster_children.map(&:gender) }.flatten.uniq.should eq ['female']
      end
            
      it 'deletes all existing associate objects' do     
        @fathers.each_has_5_children.each_has_3_children(insertion_method)
        @fathers.each do |father|        
          father.children.count.should be 3
        end    
      end
      
      it 'does not delete existing associate objects that do not belongs to items of the caller' do      
        @another_father = FactoryGirl.create :another_father
        @another_father.children << FactoryGirl.build(:child)
        @fathers.has_3_children insertion_method
        @another_father.children.count.should be 1      
      end
                     
      it 'returns caller by defaut' do      
        @fathers.each_has_3_children(insertion_method).should be @fathers      
      end
      
      it 'returns array of associate objects with :next directive' do      
        assert_array_of_children @fathers.each_has_3_children(insertion_method, :next), 3*@fathers.size      
      end
      
      it 'does not cause associate objects getting cached' do      
        @father = FactoryGirl.create :father
        [@father].each_has_3_children insertion_method
        (FactoryGirl.create :child, name:'outlaw child', father_id: @father.id)
        @father.children.detect{|child| child.name == 'outlaw child' }.should_not be_nil      
      end
    
    end
    
    describe 'using activerecord_import for database insertion' do
      
      it 'uses activerecord_import for database insertion by default' do      
        @fathers.should_receive(:create_associate_objects_for_each_item_by_import)
        @fathers.each_has_3_children 
      end
           
      it 'activates validation by default' do
        expect{ @fathers.each_has_3_children :factory => :invalid_child }.to raise_exception(DbContext::FailedImportError)
      end
      
      it 'ignores validation with :skip_validation directive' do
        expect{ @fathers.each_has_3_children :skip_validation, :factory => :invalid_child }.not_to raise_exception(DbContext::FailedImportError)
      end
      
      it_should_behave_like 'a good insertion method for Array#each_has_n_associates'
                 
    end
    
    describe 'using factory_girl for database insertion' do
      
      it 'uses factory_girl for database insertion with :girl directive' do      
        @fathers.should_receive(:create_associate_objects_for_each_item_by_factory_girl)
        @fathers.each_has_3_children :girl    
      end
      
      it_should_behave_like 'a good insertion method for Array#each_has_n_associates', :girl
      
    end  
                     
  end
  
  describe 'has method' do
    
    before :each do
      @children = 6.times.map{FactoryGirl.create(:child)}
      @fathers =  3.times.map{FactoryGirl.create(:father)}
    end
    
    it 'assigns all the associate objects to items' do
      @fathers.has @children
      @fathers.map{|father| father.children.map(&:id)}.flatten.sort.should == @children.map(&:id).sort
    end
    
    it 'allocates items equally to associate objects' do
      @fathers.has @children      
      @fathers.each {|father| father.children.count.should be @children.count/@fathers.count  }
    end    
    
    it 'allocates extra associate objects randomly' do
      @children << FactoryGirl.create(:child)
      extra_child_assigned_at_indexes = []
      100.times do
        @fathers.has @children
        @fathers.each_with_index do |father, index|
          extra_child_assigned_at_indexes << index if father.children.count == 3
        end
      end
      extra_child_assigned_at_indexes.uniq.sort.should eq [0,1,2]
    end
    
    it 'works with an explicit associate' do
      @fathers.has @children, :associate => 'foster_children'
      @fathers.map{|father| father.foster_children.map(&:id)}.flatten.sort.should == @children.map(&:id).sort
    end
    
    it 'returns the caller by default' do
      @fathers.has(@children).should be @fathers
    end
    
    it 'returns the the associate objects with :next directive' do
      @fathers.has(@children, :next).should be @children
    end
    
  end
  
  describe 'serial_update method' do
    
    it 'updates objects of the caller serially' do
      
      fathers = 5.times.map{ FactoryGirl.create :father }
      
      fathers.serial_update :number => [0,1,2,3], :name => ['zero', 'one', 'two']
      
      fathers[0].number.should   be 0
      fathers[1].number.should   be 1
      fathers[2].number.should   be 2
      fathers[3].number.should   be 3
      
      fathers[0].name.should     eq 'zero'
      fathers[1].name.should     eq 'one'
      fathers[2].name.should     eq 'two'
      
    end
    
  end    
  
  def assert_array_of_children(arr, item_count)
    arr.count.should be item_count
    arr.each do |item|
      item.class.should be Child
    end
  end
      
end  