require File.join( File.dirname(__FILE__), '..', 'rspec_helper' )

describe Array do
    
  before :each do
    @fathers = 3.times.map{ FactoryGirl.create :father }
  end
  
  describe 'serial_update method' do
    
    before :each do
      @fathers = 5.times.map{ FactoryGirl.create :father }
    end
    
    it 'updates objects of the caller serially' do
            
      @fathers.serial_update :number => [0,1,2,3], :name => ['zero', 'one', 'two']
      
      @fathers[0].number.should   be 0
      @fathers[1].number.should   be 1
      @fathers[2].number.should   be 2
      @fathers[3].number.should   be 3
      
      @fathers[0].name.should     eq 'zero'
      @fathers[1].name.should     eq 'one'
      @fathers[2].name.should     eq 'two'
      
    end
    
    it 'accepts a block and applies any changes made by the block' do
      
      @fathers.serial_update :number => [0,1,2,3,4] do |father|    
        father.name = "Father #{father.number}"       
      end
              
      @fathers.each do |father|
        father.name.should eq "Father #{father.number}"
      end
      
    end
    
    it 'makes values changed in the passed block overide values in passed attributes' do
           
      @fathers.serial_update :number => [0,1,2,3,4] do |father|    
        father.number = 1000   
      end
              
      @fathers.each do |father|
        father.number.should eq 1000
      end
            
    end
    
    it 'returns the caller' do
      @fathers.serial_update(:number => [0,1,2,3]).should be @fathers
    end
    
    it 'raises exception if attributes argument is not a hash' do     
      expect{ @fathers.serial_update([]) }.to raise_exception(TypeError)      
    end
    
  end    
   
  describe 'belong_to___association_name__ method' do
    
    before :each do
      @children = 3.times.map{ FactoryGirl.create :child }
    end
    
    it 'connects object with associated objects' do        
      @children.belong_to_fathers @fathers
      @children.map{|child| child.father.id }.should == @fathers.map(&:id)
    end
    
    it 'gets assocation name from associated class if method name does not provide an association name' do
      @children.belong_to @fathers
      @children.map{|child| child.father.id }.should == @fathers.map(&:id)
    end        
    
    it 'allocates items equally to associated objects' do
      @children = @children + 3.times.map{ FactoryGirl.create :child }
      @children.belong_to_fathers @fathers
      @fathers.each {|father| father.children.count.should be @children.count/@fathers.count  }
    end
    
    it 'allocates extra objects randomly if the number of items does not equal to the number of associated objects' do
      @children << FactoryGirl.create(:child)
      extra_child_assigned_at_indexes = []
      100.times do
        @children.belong_to_fathers(@fathers)
        @fathers.each_with_index do |father, index|
          extra_child_assigned_at_indexes << index if father.children.count == 2
        end
      end
      extra_child_assigned_at_indexes.uniq.sort.should eq [0,1,2]
    end
    
    it 'accepts a single associated object' do
      one_father = @fathers.first
      @children.belong_to_fathers one_father
      one_father.children.map(&:id).sort.should eq @children.map(&:id).sort
    end
    
    it 'accepts a block and applies any changes made by the block' do
      
      @children.belong_to_fathers(@fathers) do |child, father|
        child.name = "Child of #{father.name}"        
        father.complexion = 'yellow'                    
      end
              
      @children.each do |child|
        child.reload
        child.name.should eq "Child of #{child.father.name}"
        child.father.reload.complexion.should eq 'yellow'
      end
      
    end
    
    it 'bypasses validations when saving objects' do
            
      @children.belong_to_fathers(@fathers) do |child, father|
        child.name = ''        
        father.name = ''                    
      end
     
      @children.each do |child|
        child.reload
        child.name.should eq ''
        child.father.reload.name.should eq ''
      end
      
    end
    
    it 'returns caller by default' do
      @children.belong_to_fathers(@fathers).should be @children
    end
    
    it 'returns associated objects with :assoc directive' do
      @children.belong_to_fathers(@fathers, :assoc).should be @fathers
    end
    
    it 'does not raise exceptions if an empty array is passed' do
      expect{@children.belong_to_fathers []}.not_to raise_exception
    end      
    
    it 'raises exception if an association cannot be extracted from the method name' do
      expect{@children.belong_to_fake_associations(@fathers)}.to raise_exception(DbContext::NonExistentAssociation)
    end
    
    it 'raises exception if the association extracted from the method name is not a belongs_to association' do      
      expect{@children.belong_to_toys(@fathers)}.to raise_exception(DbContext::BelongsToAssociationExpected)
    end
    
    it 'raises exception if associated_objects argument is not an array or an ActiveRecord object' do
      expect{ @children.belong_to_fathers({}) }.to raise_exception(TypeError)      
    end
    
    it 'raises exception if invalid directives are used' do      
      expect{ @children.belong_to_fathers(@fathers, :fake) }.to raise_exception(DbContext::InvalidDirective)
    end
                     
  end
  
  describe "make___association_name__ method" do
    
    before :each do
      @children = 3.times.map{FactoryGirl.create :child}
    end
    
    it 'creates owner object for each item of array' do      
      @children.make_father
      @children.each do |child|
        child.reload.father.should_not be nil
      end
    end
    
    it 'works with an explicit factory' do
      @children.make_father :factory => :white_father
      @children.map{|child| child.father.complexion}.uniq.should eq ['white']    
    end
    
    it 'supports factory_girl traits' do
      @children.make_father :factory => [:father, :white]
      @children.map{|child| child.father.complexion}.uniq.should eq ['white']
    end
    
    it 'supports attribute values in factory' do
      @children.make_father :factory => [:father, :white, :complexion => 'black']
      @children.map{|child| child.father.complexion}.uniq.should eq ['black']      
    end
    
    it 'accepts a block and applies any changes made in the block' do
      
      @children.make_father(:factory => [:father, :white, :complexion => 'black']) do |child, father_attributes|
        child.name = "Child of #{father_attributes[:name]}"
        father_attributes[:complexion] = "yellow"        
      end
              
      @children.each do |child|
        child.reload
        child.name.should eq "Child of #{child.father.name}"
        child.father.complexion.should eq 'yellow'
      end
      
    end
    
    it 'makes values changed in the passed block overide values in factory' do
      
      @children.make_father(:factory => [:father, :white, :complexion => 'black']) do |child, father_attributes|
        father_attributes[:complexion] = "yellow"
      end
      
      @children.map{|child| child.father.complexion}.uniq.should eq ['yellow']
      
    end
    
    it 'bypasses validations when saving existing objects' do
      
      @children.make_father do |child, father_attributes|
        child.name = ''
      end
      
      @children.map(&:name).uniq.should eq ['']
      
    end
    
    it 'returns caller by default' do      
      @children.make_father.should be @children      
    end
    
    it 'returns an array of owner objects with :assoc directive' do      
      fathers = @children.make_father(:assoc)      
      @children.map{|child| child.father.id}.sort.should eq fathers.map(&:id).sort
      fathers.each do |father|
        father.class.should be Father
      end
    end
    
    it 'uses factory_girl for database insertion' do        
      FactoryGirl.should_receive(:create).exactly(@children.count).times
      @children.make_father  
    end
    
    it 'raises exception if an association cannot be extracted from the method name' do
      expect{@children.make_fake_association}.to raise_exception(DbContext::NonExistentAssociation)
    end
    
    it 'raises exception if the association extracted from the method name is not a belongs_to association' do      
      expect{@children.make_toys}.to raise_exception(DbContext::BelongsToAssociationExpected)
    end
    
    it 'raises exception if invalid directives are used' do      
      expect{ @children.make_father(:fake) }.to raise_exception(DbContext::InvalidDirective)
    end
        
  end
  
  describe 'add___association_name__ method' do
    
    before :each do
      @children = 6.times.map{FactoryGirl.create(:child)}
      @fathers =  3.times.map{FactoryGirl.create(:father)}
    end
    
    it 'assigns all the associated objects to items' do
      @fathers.add_children @children
      @fathers.map{|father| father.children.map(&:id)}.flatten.sort.should == @children.map(&:id).sort
    end
    
    it 'allocates items equally to associated objects' do
      @fathers.add_children @children      
      @fathers.each {|father| father.children.count.should be @children.count/@fathers.count  }
    end    
    
    it 'allocates extra associated objects randomly' do
      @children << FactoryGirl.create(:child)
      extra_child_assigned_at_indexes = []
      100.times do
        @fathers.add_children @children
        @fathers.each_with_index do |father, index|
          extra_child_assigned_at_indexes << index if father.children.count == 3
        end
      end
      extra_child_assigned_at_indexes.uniq.sort.should eq [0,1,2]
    end
    
    it 'accepts a block and applies any changes made by the block' do
      
      @fathers.add_children @children do |father, child|        
        father.name = 'Ben'        
        child.name = "Child of #{father.name}"        
      end
              
      @fathers.each do |father|        
        father.reload.name.should eq 'Ben'        
        father.children.each do |child|
          child.reload.name.should eq "Child of #{father.name}"
        end        
      end
      
    end
    
    it 'bypasses validations when saving existing objects' do
      
      @fathers.add_children @children do |father, child|        
        father.name = ''        
        child.name = ''
      end
      
      @fathers.map(&:name).uniq.should eq ['']
      @fathers.map{ |father| father.children.map(&:name) }.flatten.uniq.should eq ['']
                    
    end
       
    it 'returns the caller by default' do
      @fathers.add_children(@children).should be @fathers
    end
    
    it 'returns the the associated objects with :assoc directive' do
      @fathers.add_children(@children, :assoc).should be @children
    end
    
    it 'does not raise exceptions if an empty array is passed' do      
      expect{ @fathers.add_children([]) }.not_to raise_exception
    end      
    
    it 'raises exception if an association cannot be extracted from the method name' do      
      expect{@fathers.add_fake_associations(@children)}.to raise_exception(DbContext::NonExistentAssociation)
    end
    
    it 'raises exception if the association extracted from the method name is not a has_many association' do      
      expect{@fathers.add_boss @children}.to raise_exception(DbContext::HasManyAssociationExpected)
    end
    
    it 'raises exception if associated_objects argument is not an array' do     
      expect{ @fathers.add_children({}) }.to raise_exception(TypeError)      
    end
    
    it 'raises exception if invalid directives are used' do      
      expect{ @fathers.add_children(@children, :fake) }.to raise_exception(DbContext::InvalidDirective)
    end
    
  end
    
  describe 'each_has_n___association_name__ method' do        
    
    shared_examples_for 'a good insertion method for Array#each_has_n___association_name__' do |insertion_method|
    
      it 'creates n associated objects for each item of array' do      
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
      
      it 'accepts a block and applies changes made in the block' do
        
        @fathers.each_has_3_foster_children(insertion_method, :factory => :child) do |father, child_attributes|
          father.complexion = 'yellow'
          child_attributes['name'] = "Child of #{father.name}"
        end
        
        @fathers.each do |father|
          father.reload.complexion.should eq 'yellow'
          father.foster_children.each do |child|
            child.name.should eq "Child of #{father.name}"
          end
        end
        
      end
      
      it 'makes values changed in the passed block overide values in factory' do
        @fathers.each_has_3_foster_children insertion_method, :factory => [:child, :male, :gender => 'female'] do |father, foster_child_attributes|
          foster_child_attributes[:gender] = 'male'
        end
        @fathers.map { |father| father.foster_children.map(&:gender) }.flatten.uniq.should eq ['male']
      end
      
      it 'bypasses validations when saving existing objects' do
        
        @fathers.each_has_3_children(insertion_method) do |father, child_attributes|
          father.name = ''
        end
        
        @fathers.map(&:name).uniq.should eq ['']
        
      end
            
      it 'deletes all existing associated objects' do     
        @fathers.each_has_5_children.each_has_3_children(insertion_method)
        @fathers.each do |father|        
          father.children.count.should be 3
        end    
      end
      
      it 'does not delete existing associated objects that do not belongs to items of the caller' do      
        @another_father = FactoryGirl.create :another_father
        @another_father.children << FactoryGirl.build(:child)
        @fathers.has_3_children insertion_method
        @another_father.children.count.should be 1      
      end
                     
      it 'returns caller by defaut' do      
        @fathers.each_has_3_children(insertion_method).should be @fathers      
      end
      
      it 'returns array of associated objects with :assoc directive' do      
        assert_array_of_children @fathers.each_has_3_children(insertion_method, :assoc), 3*@fathers.size      
      end
      
      it 'does not cause associated objects getting cached' do      
        @father = FactoryGirl.create :father
        [@father].each_has_3_children insertion_method
        (FactoryGirl.create :child, name:'outlaw child', father_id: @father.id)
        @father.children.detect{|child| child.name == 'outlaw child' }.should_not be_nil      
      end
    
    end
    
    describe 'using activerecord_import for database insertion' do
      
      it 'uses activerecord_import for database insertion by default' do      
        @fathers.should_receive(:create_associated_objects_for_each_item_by_import)
        @fathers.each_has_3_children 
      end
           
      it 'activates validation by default' do
        expect{ @fathers.each_has_3_children :factory => :invalid_child }.to raise_exception
      end
      
      it 'ignores validation with :skip_validation directive' do
        expect{ @fathers.each_has_3_children :skip_validation, :factory => :invalid_child }.not_to raise_exception
      end
      
      it_should_behave_like 'a good insertion method for Array#each_has_n___association_name__'
                 
    end
    
    describe 'using factory_girl for database insertion' do
      
      it 'uses factory_girl for database insertion with :girl directive' do        
        FactoryGirl.should_receive(:create).exactly(9).times
        @fathers.each_has_3_children :girl    
      end
      
      it_should_behave_like 'a good insertion method for Array#each_has_n___association_name__', :girl
      
    end
    
    it 'raises exception if an association cannot be extracted from the method name' do      
      expect{@fathers.each_has_1_fake_associations}.to raise_exception(DbContext::NonExistentAssociation)
    end
    
    it 'raises exception if the association extracted from the method name is not a has_many association' do      
      expect{@fathers.each_has_1_boss}.to raise_exception(DbContext::HasManyAssociationExpected)
    end
    
    it 'raises exception if invalid directives are used' do      
      expect{ @fathers.each_has_3_children(:fake) }.to raise_exception(DbContext::InvalidDirective)
    end
                     
  end
  
  describe 'has_n___association_name__ method' do       
    
    shared_examples_for 'a good insertion method for Array#has_n___association_name__' do |insertion_method|
    
      it 'creates n associated objects for all items of the caller' do      
        @fathers.has_5_children insertion_method
        @fathers.sum{|father| father.children.count }.should be 5      
      end                   
      
      it 'deletes all existing associated objects of items in the caller' do      
        @fathers.has_5_children.has_3_children insertion_method
        @fathers.sum{|father| father.children.count }.should be 3      
      end
      
      it 'does not delete existing associated objects that do not belongs to items in the caller' do     
        @another_father = FactoryGirl.create :another_father
        @another_father.children << FactoryGirl.build(:child)
        @fathers.has_3_children insertion_method
        @another_father.children.count.should be 1      
      end  
      
      it 'assigns associated objects equally to items' do
        @fathers.has_6_children insertion_method
        @fathers.each do |father|
          father.children.count.should be 2
        end
      end
      
      it 'assigns extra associated objects randomly to items' do     
        child_counts = []
        100.times do
          @fathers.has_8_children insertion_method
          @fathers.each do |father|          
            child_counts << father.children.count
          end        
        end      
        child_counts.uniq.sort.should == [2,3,4]      
      end
      
      it 'does not cause associated objects getting cached' do     
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
      
      it 'accepts a block and applies changes made in the block' do     
        @fathers.has_5_children(insertion_method) do |father, child_attributes|
          father.complexion = 'yellow'
          child_attributes['name'] = "Child of #{father.name}"
        end
        @fathers.each do |father|
          father.reload.complexion.should eq 'yellow'
          father.foster_children.each do |child|
            child.name.should eq "Child of #{father.name}"
          end
        end
      end
      
      it 'makes values changed in the passed block overide values in factory and options[:data]' do
        @fathers.has_5_foster_children insertion_method, :factory => [:child, :male, :gender => 'female'], :data => [{:gender => 'neutral'}]*5 do |father, foster_child_attributes|
          foster_child_attributes[:gender] = 'male'
        end
        @fathers.map { |father| father.foster_children.map(&:gender) }.flatten.uniq.should eq ['male']
      end
      
      it 'bypasses validations when saving existing objects' do
        
        @fathers.has_5_children(insertion_method) do |father, child_attributes|
          father.name = ''         
        end
        
        @fathers.map(&:name).uniq.should eq ['']
        
      end
      
      it 'returns caller by default' do      
        @fathers.has_3_children(insertion_method).should be @fathers      
      end
      
      it 'returns array of associated objects if with :assoc directive' do      
        assert_array_of_children @fathers.has_3_children(insertion_method, :assoc), 3      
      end
    
    end
  
    describe 'using activerecord_import for database insertion' do
      
      it 'uses activerecord_import for database insertion by default' do        
        @fathers.should_receive(:create_associated_objects_by_import_using_allocating_schema)
        @fathers.has_3_children
      end           
      
      it 'activates validation by default' do
        expect{ @fathers.has_3_children :factory => :invalid_child }.to raise_exception(DbContext::FailedImportError)
      end
      
      it 'ignores validation with :skip_validation directive' do
        expect{ @fathers.has_3_children :skip_validation, :factory => :invalid_child }.not_to raise_exception
      end
      
      it_should_behave_like 'a good insertion method for Array#has_n___association_name__'
      
    end
    
    describe 'using factory_girl for database insertion' do
      
      it 'uses factory_girl for database insertion with :girl directive' do        
        @fathers.should_receive(:create_associated_objects_by_factory_girl_using_allocating_schema)
        @fathers.has_3_children :girl
      end
      
      it_should_behave_like 'a good insertion method for Array#has_n___association_name__', :girl
      
    end
    
    it 'raises exception if an association cannot be extracted from the method name' do
      expect{@fathers.have_3_fake_associations}.to raise_exception(DbContext::NonExistentAssociation)
    end
    
    it 'raises exception if the association extracted from the method name is not a has_many association' do      
      expect{@fathers.have_3_boss}.to raise_exception(DbContext::HasManyAssociationExpected)
    end
    
    it 'raises exception if invalid directives are used' do      
      expect{ @fathers.has_3_children :fake }.to raise_exception(DbContext::InvalidDirective)
    end
    
  end
  
  describe 'random_update_n___association_name__' do
    
    before :each do
      @fathers.each_has_4_children
    end
    
    it 'updates n associated objects' do     
      @fathers.random_update_2_children name:'updated_name'
      @fathers.each do |father|
        father.children.where(:name => 'updated_name').count.should be 2
      end
    end
    
    it 'updates n associated objects randomly' do
      
      @fathers = Father.create_1
      
      updated_indexes = []
            
      100.times do
        Child.destroy_all
        @fathers.each_has_4_children
        @fathers.random_update_1_children(name:'updated_name')
        @fathers.first.reload.children.order('id asc').each_with_index do |child, index|          
          updated_indexes << index if child.name == 'updated_name'
        end        
      end      
      
      updated_indexes.uniq.sort.should == [0,1,2,3]
      
    end
    
    it 'accepts a block and applies any changes made by the block' do
            
      @fathers.random_update_2_children name:'updated_name' do |father, updated_child|        
        father.name = 'Ben'        
        updated_child.gender = "neutral"        
      end
           
      @fathers.each do |father|        
        father.reload.name.should eq 'Ben'  
        father.children.each do |child|
          child.reload.gender.should eq "neutral" if child.name == 'updated_name'
        end        
      end
      
    end
    
    it 'makes values changed in the passed block overide values in passed attributes' do
           
      @fathers.random_update_2_children name:'updated_name' do |father, updated_child|              
        updated_child.name = "updated name in block"        
      end
      
      @fathers.each do |father|
        father.children.where(:name => 'updated_name').count.should be 0
        father.children.where(:name => 'updated name in block').count.should be 2
      end
            
    end
    
    it 'bypasses validations when saving objects' do
      
      @fathers.random_update_2_children name:'' do |father, updated_child|
        father.name = ''       
      end
      
      @fathers.map(&:name).uniq.should eq ['']
      
      @fathers.each do |father|        
        father.children.where(:name => '').count.should be 2
      end
      
    end
    
    it 'returns caller by default' do
      @fathers.random_update_1_children(:name => 'updated_name').should be @fathers
    end
    
    it 'returns updated associated objects with :assoc directive' do      
      result = @fathers.random_update_2_children({:name => 'updated_name'}, :assoc)
      assert_array_of_children(result, 2*@fathers.count)
      result.map(&:id).sort.should eq @fathers.map{|father| father.children.where(:name => 'updated_name').map(&:id) }.flatten.sort
    end
    
    it 'raises an exception if an association cannot be extracted from the method name' do
      expect{@fathers.random_update_1_fake_associations(name:'updated_name')}.to raise_exception(DbContext::NonExistentAssociation)
    end
    
    it 'raises an exception if the association extracted from the method name is not a has_many association' do      
      expect{@fathers.random_update_1_boss(name:'updated_name')}.to raise_exception(DbContext::HasManyAssociationExpected)
    end
    
     it 'raises exception if attributes argument is not a hash' do      
      expect{ @fathers.random_update_2_children([]) }.to raise_exception(TypeError)      
    end
     
     it 'raises exception if invalid directives are used' do      
      expect{ @fathers.random_update_2_children({:name => 'updated_name'}, :fake) }.to raise_exception(DbContext::InvalidDirective)
    end
    
  end  
          
  def assert_array_of_children(arr, item_count)
    arr.count.should be item_count
    arr.each do |item|
      item.class.should be Child
    end
  end
      
end  