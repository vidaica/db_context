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
      
      expect(@fathers[0].number).to   be 0
      expect(@fathers[1].number).to   be 1
      expect(@fathers[2].number).to   be 2
      expect(@fathers[3].number).to   be 3
      
      expect(@fathers[0].name).to     eq 'zero'
      expect(@fathers[1].name).to     eq 'one'
      expect(@fathers[2].name).to     eq 'two'
      
    end
    
    it 'accepts a block and applies any changes made by the block' do
      
      @fathers.serial_update :number => [0,1,2,3,4] do |father|    
        father.name = "Father #{father.number}"       
      end
              
      @fathers.each do |father|
        expect(father.name).to eq "Father #{father.number}"
      end
      
    end
    
    it 'makes values changed in the passed block overide values in passed attributes' do
           
      @fathers.serial_update :number => [0,1,2,3,4] do |father|    
        father.number = 1000   
      end
              
      @fathers.each do |father|
        expect(father.number).to eq 1000
      end
            
    end
    
    it 'returns the caller' do
      expect(@fathers.serial_update(:number => [0,1,2,3])).to be @fathers
    end
    
    it 'raises exception if attributes argument is not a hash' do     
      expect{ @fathers.serial_update([]) }.to raise_exception(TypeError)      
    end
        
    it 'does nothing if the method is called on an emty array' do
      @fathers = []
      expect(@fathers.serial_update(:number => [0,1,2,3])).to be @fathers
    end
    
  end    
   
  describe 'belong_to___association_name__ method' do
    
    before :each do
      @children = 3.times.map{ FactoryGirl.create :child }
    end
    
    it 'connects object with associated objects' do        
      @children.belong_to_fathers @fathers
      expect(@children.map{|child| child.father.id }).to eq @fathers.map(&:id)
    end
    
    it 'gets assocation name from associated class if method name does not provide an association name' do
      @children.belong_to @fathers
      expect(@children.map{|child| child.father.id }).to eq @fathers.map(&:id)
    end        
    
    it 'allocates items equally to associated objects' do
      @children = @children + 3.times.map{ FactoryGirl.create :child }
      @children.belong_to_fathers @fathers
      @fathers.each {|father| expect(father.children.count).to be @children.count/@fathers.count  }
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
      expect(extra_child_assigned_at_indexes.uniq.sort).to eq [0,1,2]
    end
    
    it 'accepts a single associated object' do
      one_father = @fathers.first
      @children.belong_to_fathers one_father
      expect(one_father.children.map(&:id).sort).to eq @children.map(&:id).sort
    end
    
    it 'accepts a block and applies any changes made by the block' do
      
      @children.belong_to_fathers(@fathers) do |child, father|
        child.name = "Child of #{father.name}"        
        father.complexion = 'yellow'                    
      end
              
      @children.each do |child|
        child.reload
        expect(child.name).to eq "Child of #{child.father.name}"
        expect(child.father.reload.complexion).to eq 'yellow'
      end
      
    end
    
    it 'bypasses validations when saving objects' do
            
      @children.belong_to_fathers(@fathers) do |child, father|
        child.name = ''        
        father.name = ''                    
      end
     
      @children.each do |child|
        child.reload
        expect(child.name).to eq ''
        expect(child.father.reload.name).to eq ''
      end
      
    end
    
    it 'returns caller by default' do
      expect(@children.belong_to_fathers(@fathers)).to be @children
    end
    
    it 'returns associated objects with :assoc directive' do
      @father = @fathers.first
      expect(@children.belong_to_fathers(@fathers, :assoc)).to be @fathers
      expect(@children.belong_to_fathers(@father, :assoc)).to be @father
    end
    
    it 'does nothing if an empty array is passed' do
      @fathers = []
      expect(@children.belong_to_fathers(@fathers)).to be @children
      expect(@children.belong_to_fathers(@fathers, :assoc)).to be @fathers
    end
    
    it 'does nothing if the method is called on an emty array' do
      @children = []
      expect(@children.belong_to_fathers(@fathers)).to be @children
      expect(@children.belong_to_fathers(@fathers, :assoc)).to be @fathers
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
        expect(child.reload.father).not_to be nil
      end
    end
    
    it 'works with an explicit factory' do
      @children.make_father :factory => :white_father
      expect(@children.map{|child| child.father.complexion}.uniq).to eq ['white']    
    end
    
    it 'supports factory_girl traits' do
      @children.make_father :factory => [:father, :white]
      expect(@children.map{|child| child.father.complexion}.uniq).to eq ['white']
    end
    
    it 'supports attribute values in factory' do
      @children.make_father :factory => [:father, :white, :complexion => 'black']
      expect(@children.map{|child| child.father.complexion}.uniq).to eq ['black']      
    end
    
    it 'accepts a block and applies any changes made in the block' do
      
      @children.make_father(:factory => [:father, :white, :complexion => 'black']) do |child, father_attributes|
        child.name = "Child of #{father_attributes[:name]}"
        father_attributes[:complexion] = "yellow"        
      end
              
      @children.each do |child|
        child.reload
        expect(child.name).to eq "Child of #{child.father.name}"
        expect(child.father.complexion).to eq 'yellow'
      end
      
    end
    
    it 'makes values changed in the passed block overide values in factory' do
      
      @children.make_father(:factory => [:father, :white, :complexion => 'black']) do |child, father_attributes|
        father_attributes[:complexion] = "yellow"
      end
      
      expect(@children.map{|child| child.father.complexion}.uniq).to eq ['yellow']
      
    end
    
    it 'bypasses validations when saving existing objects' do
      
      @children.make_father do |child, father_attributes|
        child.name = ''
      end
      
      expect(@children.map(&:name).uniq).to eq ['']
      
    end
    
    it 'returns caller by default' do      
      expect(@children.make_father).to be @children      
    end
    
    it 'returns an array of owner objects with :assoc directive' do      
      fathers = @children.make_father(:assoc)      
      expect(@children.map{|child| child.father.id}.sort).to eq fathers.map(&:id).sort
      fathers.each do |father|
        expect(father.class).to be Father
      end
    end
    
    it 'uses factory_girl for database insertion' do        
      expect(FactoryGirl).to receive(:create).exactly(@children.count).times
      @children.make_father  
    end
    
    it 'does nothing if the method is called on an emty array' do
      @children = []
      expect(@children.make_father).to be @children
      expect(@children.make_father(:assoc)).to eq []
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
      expect(@fathers.map{|father| father.children.map(&:id)}.flatten.sort).to eq @children.map(&:id).sort
    end
    
    it 'allocates items equally to associated objects' do
      @fathers.add_children @children      
      @fathers.each {|father| expect(father.children.count).to be @children.count/@fathers.count  }
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
      expect(extra_child_assigned_at_indexes.uniq.sort).to eq [0,1,2]
    end
    
    it 'accepts a block and applies any changes made by the block' do
      
      @fathers.add_children @children do |father, child|        
        father.name = 'Ben'        
        child.name = "Child of #{father.name}"        
      end
              
      @fathers.each do |father|        
        expect(father.reload.name).to eq 'Ben'        
        father.children.each do |child|
          expect(child.reload.name).to eq "Child of #{father.name}"
        end        
      end
      
    end
    
    it 'bypasses validations when saving existing objects' do
      
      @fathers.add_children @children do |father, child|        
        father.name = ''        
        child.name = ''
      end
      
      expect(@fathers.map(&:name).uniq).to eq ['']
      expect(@fathers.map{ |father| father.children.map(&:name) }.flatten.uniq).to eq ['']
                    
    end
    
    it 'does nothing if the method is called on an emty array' do
      @fathers = []
      expect(@fathers.add_children(@children)).to be @fathers
      expect(@fathers.add_children(@children, :assoc)).to be @children
    end
       
    it 'returns the caller by default' do
      expect(@fathers.add_children(@children)).to be @fathers
    end
    
    it 'returns the the associated objects with :assoc directive' do
      expect(@fathers.add_children(@children, :assoc)).to be @children
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
          expect(father.children.count).to be 3
        end      
      end
      
      it 'works with an explicit factory' do      
        @fathers.each_has_3_foster_children insertion_method, :factory => :child
        @fathers.each do |father|        
          expect(father.foster_children.count).to be 3
        end
      end
      
      it 'supports factory_girl traits' do
        @fathers.each_has_3_foster_children insertion_method, :factory => [:child, :male]
        expect(@fathers.map { |father| father.foster_children.map(&:gender) }.flatten.uniq).to eq ['male'] 
      end
      
      it 'supports attribute values in factory' do
        @fathers.each_has_3_foster_children insertion_method, :factory => [:child, :male, :gender => 'female']
        expect(@fathers.map { |father| father.foster_children.map(&:gender) }.flatten.uniq).to eq ['female']
      end
      
      it 'accepts a block and applies changes made in the block' do
        
        @fathers.each_has_3_foster_children(insertion_method, :factory => :child) do |father, child_attributes|
          father.complexion = 'yellow'
          child_attributes['name'] = "Child of #{father.name}"
        end
        
        @fathers.each do |father|
          expect(father.reload.complexion).to eq 'yellow'
          father.foster_children.each do |child|
            expect(child.name).to eq "Child of #{father.name}"
          end
        end
        
      end
      
      it 'makes values changed in the passed block overide values in factory' do
        @fathers.each_has_3_foster_children insertion_method, :factory => [:child, :male, :gender => 'female'] do |father, foster_child_attributes|
          foster_child_attributes[:gender] = 'male'
        end
        expect(@fathers.map { |father| father.foster_children.map(&:gender) }.flatten.uniq).to eq ['male']
      end
      
      it 'bypasses validations when saving existing objects' do
        
        @fathers.each_has_3_children(insertion_method) do |father, child_attributes|
          father.name = ''
        end
        
        expect(@fathers.map(&:name).uniq).to eq ['']
        
      end
            
      it 'deletes all existing associated objects' do     
        @fathers.each_has_5_children.each_has_3_children(insertion_method)
        @fathers.each do |father|        
          expect(father.children.count).to be 3
        end    
      end
      
      it 'does not delete existing associated objects that do not belongs to items of the caller' do      
        @another_father = FactoryGirl.create :another_father
        @another_father.children << FactoryGirl.build(:child)
        @fathers.has_3_children insertion_method
        expect(@another_father.children.count).to be 1      
      end
      
      it 'does nothing if the method is called on an emty array' do
        @fathers = []
        expect(@fathers.each_has_3_children).to be @fathers
        expect(@fathers.each_has_3_children(:assoc)).to eq []
      end
                     
      it 'returns caller by defaut' do      
        expect(@fathers.each_has_3_children(insertion_method)).to be @fathers      
      end
      
      it 'returns array of associated objects with :assoc directive' do                     
        expect(@fathers.each_has_3_children(insertion_method, :assoc)).to be_an_array_of(Child).with(3*@fathers.size).items
      end
      
      it 'does not cause associated objects getting cached' do      
        @father = FactoryGirl.create :father
        [@father].each_has_3_children insertion_method
        (FactoryGirl.create :child, name:'outlaw child', father_id: @father.id)
        expect(@father.children.detect{|child| child.name == 'outlaw child' }).not_to be nil      
      end
    
    end
    
    describe 'using activerecord_import for database insertion' do
      
      it 'uses activerecord_import for database insertion by default' do      
        expect(@fathers).to receive(:create_associated_objects_for_each_item_by_import)
        @fathers.each_has_3_children 
      end
           
      it 'activates validation by default' do
        expect{ @fathers.each_has_3_children :factory => :invalid_child }.to raise_exception(Exception)
      end
      
      it 'ignores validation with :skip_validation directive' do
        expect{ @fathers.each_has_3_children :skip_validation, :factory => :invalid_child }.not_to raise_exception
      end
      
      it_should_behave_like 'a good insertion method for Array#each_has_n___association_name__'
                 
    end
    
    describe 'using factory_girl for database insertion' do
      
      it 'uses factory_girl for database insertion with :girl directive' do        
        expect(FactoryGirl).to receive(:create).exactly(9).times
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
    
    it 'raises exception if :girl and :skip_validation directives are used together' do     
      expect{ @fathers.each_has_3_children(:girl, :skip_validation) }.to raise_exception(DbContext::ConflictDirectives)
    end
                     
  end
  
  describe 'has_n___association_name__ method' do       
    
    shared_examples_for 'a good insertion method for Array#has_n___association_name__' do |insertion_method|
    
      it 'creates n associated objects for all items of the caller' do      
        @fathers.has_5_children insertion_method
        expect(@fathers.sum{|father| father.children.count }).to be 5      
      end                   
      
      it 'deletes all existing associated objects of items in the caller' do      
        @fathers.has_5_children.has_3_children insertion_method
        expect(@fathers.sum{|father| father.children.count }).to be 3      
      end
      
      it 'does not delete existing associated objects that do not belongs to items in the caller' do     
        @another_father = FactoryGirl.create :another_father
        @another_father.children << FactoryGirl.build(:child)
        @fathers.has_3_children insertion_method
        expect(@another_father.children.count).to be 1      
      end  
      
      it 'assigns associated objects equally to items' do
        @fathers.has_6_children insertion_method
        @fathers.each do |father|
          expect(father.children.count).to be 2
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
        expect(child_counts.uniq.sort).to eq [2,3,4]      
      end
      
      it 'does not cause associated objects getting cached' do     
        @father = FactoryGirl.create :father
        [@father].has_3_children insertion_method
        (FactoryGirl.create :child, name:'outlaw child', father_id: @father.id)
        expect(@father.children.detect{|child| child.name == 'outlaw child' }).not_to be nil
      end
      
      it 'works with provided data do' do        
        @fathers.has_3_children( insertion_method, data: [ {name: 'Ti' }, {name: 'Teo'} ] )
        child1 = @fathers[0].children.first
        child2 = @fathers[1].children.first
        expect(child1.name).to eq 'Ti'
        expect(child2.name).to eq 'Teo'
        
      end
      
      it 'works with an explicit factory' do      
        @fathers.has_5_foster_children insertion_method, :factory => :child
        expect(@fathers.sum{|father| father.foster_children.count }).to be 5
      end
      
      it 'supports factory_girl traits' do
        @fathers.has_5_foster_children insertion_method, :factory => [:child, :male]
        expect(@fathers.map { |father| father.foster_children.map(&:gender) }.flatten.uniq).to eq ['male'] 
      end
      
      it 'supports attribute values in factory' do
        @fathers.has_5_foster_children insertion_method, :factory => [:child, :male, :gender => 'female']
        expect(@fathers.map { |father| father.foster_children.map(&:gender) }.flatten.uniq).to eq ['female']
      end
      
      it 'makes values in options[:data] overide values in factory' do        
        @fathers.has_5_foster_children insertion_method, :factory => [:child, :male, :gender => 'female'], :data => [{:gender => 'neutral'}]*5
        expect(@fathers.map { |father| father.foster_children.map(&:gender) }.flatten.uniq).to eq ['neutral']
      end
      
      it 'accepts a block and applies changes made in the block' do     
        @fathers.has_5_children(insertion_method) do |father, child_attributes|
          father.complexion = 'yellow'
          child_attributes['name'] = "Child of #{father.name}"
        end
        @fathers.each do |father|
          expect(father.reload.complexion).to eq 'yellow'
          father.foster_children.each do |child|
            expect(child.name).to eq "Child of #{father.name}"
          end
        end
      end
      
      it 'makes values changed in the passed block overide values in factory and options[:data]' do
        @fathers.has_5_foster_children insertion_method, :factory => [:child, :male, :gender => 'female'], :data => [{:gender => 'neutral'}]*5 do |father, foster_child_attributes|
          foster_child_attributes[:gender] = 'male'
        end
        expect(@fathers.map { |father| father.foster_children.map(&:gender) }.flatten.uniq).to eq ['male']
      end
      
      it 'bypasses validations when saving existing objects' do
        
        @fathers.has_5_children(insertion_method) do |father, child_attributes|
          father.name = ''         
        end
        
        expect(@fathers.map(&:name).uniq).to eq ['']
        
      end
      
      it 'does nothing if the method is called on an emty array' do
        @fathers = []
        expect(@fathers.has_5_children(insertion_method)).to be @fathers
        expect(@fathers.has_5_children(insertion_method, :assoc)).to eq []
      end
      
      it 'returns caller by default' do      
        expect(@fathers.has_3_children(insertion_method)).to be @fathers      
      end
      
      it 'returns array of associated objects if with :assoc directive' do
        expect(@fathers.has_3_children(insertion_method, :assoc)).to be_an_array_of(Child).with(3).items        
      end        
    
    end
  
    describe 'using activerecord_import for database insertion' do
      
      it 'uses activerecord_import for database insertion by default' do        
        expect(@fathers).to receive(:create_associated_objects_by_import_using_allocating_schema)
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
        expect(@fathers).to receive(:create_associated_objects_by_factory_girl_using_allocating_schema)
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
    
    it 'raises exception if :girl and :skip_validation directives are used together' do      
      expect{ @fathers.has_3_children(:girl, :skip_validation) }.to raise_exception(DbContext::ConflictDirectives)
    end
    
  end
  
  describe 'random_update_n___association_name__' do
    
    before :each do
      @fathers.each_has_4_children
    end
    
    it 'updates n associated objects' do     
      @fathers.random_update_2_children name:'updated_name'
      @fathers.each do |father|
        expect(father.children.where(:name => 'updated_name').count).to be 2
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
      
      expect(updated_indexes.uniq.sort).to eq [0,1,2,3]
      
    end
    
    it 'accepts a block and applies any changes made by the block' do
            
      @fathers.random_update_2_children name:'updated_name' do |father, updated_child|        
        father.name = 'Ben'        
        updated_child.gender = "neutral"        
      end
           
      @fathers.each do |father|        
        expect(father.reload.name).to eq 'Ben'  
        father.children.each do |child|
          expect(child.reload.gender).to eq "neutral" if child.name == 'updated_name'
        end        
      end
      
    end
    
    it 'makes values changed in the passed block overide values in passed attributes' do
           
      @fathers.random_update_2_children name:'updated_name' do |father, updated_child|              
        updated_child.name = "updated name in block"        
      end
      
      @fathers.each do |father|
        expect(father.children.where(:name => 'updated_name').count).to be 0
        expect(father.children.where(:name => 'updated name in block').count).to be 2
      end
            
    end
    
    it 'bypasses validations when saving objects' do
      
      @fathers.random_update_2_children name:'' do |father, updated_child|
        father.name = ''       
      end
      
      expect(@fathers.map(&:name).uniq).to eq ['']
      
      @fathers.each do |father|        
        expect(father.children.where(:name => '').count).to be 2
      end
      
    end
    
    it 'returns caller by default' do
      expect(@fathers.random_update_1_children(:name => 'updated_name')).to be @fathers
    end
    
    it 'returns updated associated objects with :assoc directive' do      
      result = @fathers.random_update_2_children({:name => 'updated_name'}, :assoc)     
      expect(result).to be_an_array_of(Child).with(2*@fathers.count).items
      expect(result.map(&:id).sort).to eq @fathers.map{|father| father.children.where(:name => 'updated_name').map(&:id) }.flatten.sort
    end
    
    it 'does nothing if the method is called on an emty array' do
      @fathers = []
      expect(@fathers.random_update_1_children(:name => 'updated_name')).to be @fathers
      expect(@fathers.random_update_1_children({:name => 'updated_name'}, :assoc)).to eq []
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
      
end  