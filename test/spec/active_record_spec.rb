require File.join( File.dirname(__FILE__), '..', 'rspec_helper' )

describe ActiveRecord::Base do
  
  describe 'has method' do
    
    before :each do
      @data = [{:name => 'father1'}, {:name => 'father2'}, {:name => 'father3'}] 
    end
    
    describe 'creates n instances' do
                   
      it 'works without a factory' do                        
        expect{ Father.has @data }.to change(Father, :count).by( @data.count )
      end
      
      it 'works with a factory' do
        expect{ Father.has @data, :another_father }.to change(Father, :count).by( @data.count )
      end
      
    end
    
    describe 'returns an array of newly created instances' do
      
      it 'works with default factory' do
        returned = Father.has @data
        returned.class.should == Array
        returned.map(&:id).should == Father.last(3).map(&:id)
      end
      
      it 'work with passing factory' do 
        returned = Father.has @data, :another_father
        returned.class.should == Array
        returned.map(&:id).should == Father.last(3).map(&:id)
      end
      
    end
    
    it 'activates validation by default' do
      expect{ Father.has [{:name => ''}] }.to raise_exception(FailedImportError)
    end
    
    it 'ignores validation if :validate option is set to false' do
      expect{ Father.has [{:name => ''}], :father, :validate => false }.not_to raise_exception(FailedImportError)
    end
  
  end
  
  describe 'has_associates method' do
    
    before :each do
      @father = FactoryGirl.create :father
    end
    
    it 'creates right number of associate objects using passed data' do      
      @father.has_children [{:name => 'children1'}, {:name => 'children2'}]
      @father.children.count.should == 2
      @father.children.where(['name in (?)', ['children1', 'children2'] ]).count.should == 2
    end
    
    it 'remove existing associate objects' do
      @father.children.create(FactoryGirl.attributes_for :child)
      @father.has_children [{:name => 'child1'}, {:name => 'child2'}]
      @father.children.count.should be_equal(2)
    end
    
    it 'does not cache associate objects' do
      @father.has_children [{:name => 'child1'}, {:name => 'child2'}]
      FactoryGirl.create(:child, name: 'an_extra_child').update_attribute('father_id', @father.id)
      @father.children.detect{|child| child.name == 'an_extra_child'}.should_not be_nil      
    end
    
    it 'returns array of children if factory is :here' do
      returned = @father.has_children [{:name => 'child1'}, {:name => 'child2'}], :here
      assert_array_of_children returned, 2
    end
    
    it 'returns array of children if return_what is :here' do
      returned = @father.has_children [{:name => 'child1'}, {:name => 'child2'}], :child, :here
      assert_array_of_children returned, 2
    end      
    
    it 'returns self with defaut parameters' do     
      returned = @father.has_children [{:name => 'child1'}, {:name => 'child2'}]
      returned.should === @father      
    end
    
    it 'activates validation by default' do
      expect{ @father.has_children [{:name => ''}] }.to raise_exception(FailedImportError)
    end
    
    it 'ignores validation if :validate option is set to false' do
      expect{ @father.has_children [{:name => ''}], :child, :validate => false }.not_to raise_exception(FailedImportError)
    end
    
  end
  
  describe 'has_n_associates method' do
    
    before :each do
      @father = FactoryGirl.create :father
    end
    
    it 'creates n associate objects' do
      expect{ @father.has_3_children }.to change(@father.children, :count).by(3)
    end
    
    it 'remove existing associate objects' do      
      @father.children.create(FactoryGirl.attributes_for :child)
      @father.has_3_children      
      @father.children.count.should be_equal(3)
    end       
    
    it 'does not cache associate objects' do
      @father.has_3_children
      FactoryGirl.create(:child, name: 'an_extra_child').update_attribute('father_id', @father.id)
      @father.children.detect{|child| child.name == 'an_extra_child'}.should_not be_nil      
    end
    
    it 'returns array of children if factory is :here' do
      assert_array_of_children @father.has_3_children(:here), 3     
    end
    
    it 'returns array of children if return_what is :here' do
      assert_array_of_children @father.has_3_children(:child, :here), 3
    end      
    
    it 'returns self with defaut parameters' do     
      returned = @father.has_3_children
      returned.should === @father      
    end
    
  end
  
  describe 'create_n_instances method' do
    
    describe 'create_method is :import' do
      
      describe 'creates n instances' do
        
        it 'works without a factory' do        
          expect{ Father.create_3 :import }.to change(Father, :count).by(3)
        end
        
        it 'works with a factory' do
          expect{ Father.create_3 :import, :another_father }.to change(Father, :count).by(3)
        end
        
      end
      
      describe 'returns an array of newly created instances' do
        
        it 'works with default factory' do
          returned = Father.create_3 :import
          returned.class.should == Array
          returned.map(&:id).should == Father.last(3).map(&:id)
        end
        
        it 'work with passing factory' do 
          returned = Father.create_3 :import, :another_father
          returned.class.should == Array
          returned.map(&:id).should == Father.last(3).map(&:id)
        end
        
      end
      
      it 'activates validation by default' do
        expect{ Father.create_3 :import, :invalid_father }.to raise_exception(FailedImportError)
      end
      
      it 'ignores validation if :validate option is set to false' do
        expect{ Father.create_3 :import, :invalid_father, :validate => false }.to change(Father, :count).by(3)
      end
                  
    end
    
    describe 'create_method is :factory' do
      
      describe 'creates n instances' do
        
        it 'works with default factory' do
          expect{ Father.create_3 :factory }.to change(Father, :count).by(3)
        end
        it 'works with passing a factory' do
          expect{ Father.create_3 :factory, :another_father }.to change(Father, :count).by(3)
        end
        
      end
      
      describe 'returns an array of newly created instances' do
        
        it 'works with default factory' do
          returned = Father.create_3 :factory
          returned.class.should == Array
          returned.map(&:id).should == Father.last(3).map(&:id)
        end
      
        it 'works with passing factory' do
          returned = Father.create_3 :factory, :another_father
          returned.class.should == Array
          returned.map(&:id).should == Father.last(3).map(&:id)
        end
    
      end
      
    end        
        
    it 'works with default arguments' do
      expect{ Father.create_3 }.to change(Father, :count).by(3)
    end    
    
  end    
  
  describe 'belongs_to_associate method' do
    
    before :each do
      @father = FactoryGirl.create :father
      @child = FactoryGirl.create :child      
    end
    
    it 'takes the passed object as owner' do
      @child.belongs_to @father
      @child.father.id.should == @father.id
    end
    
    it 'returns calling object' do
      returned = @child.belongs_to @father
      returned.should === @child
    end
    
  end
  
  describe 'one method' do
    
    describe 'create_method is :import' do
      
      describe 'creates one object of the calling class' do
        
        it 'works with default factory' do
          expect{ Father.one :import }.to change(Father, :count).by(1)
        end
        
        it 'works with passing factory' do
          expect{ Father.one :import, :another_father }.to change(Father, :count).by(1)
        end
        
      end
      
      describe 'returns the newly created object' do
        
        it 'works with default factory' do
          returned = Father.one :import
          returned.class.should == Father
          returned.should == Father.last
        end
        
        it 'works with passing factory' do
          returned = Father.one :import, :another_father
          returned.class.should == Father
          returned.should == Father.last
        end
        
      end
      
      it 'activates validation by default' do
        expect{ Father.one :import, :invalid_father }.to raise_exception(FailedImportError)
      end
      
      it 'ignores validation if :validate option is set to false' do
        expect{ Father.one :import, :invalid_father, :validate => false }.to change(Father, :count).by(1)
      end
                  
    end
    
    describe 'create_method is :factory' do
      
      describe 'creates n instances' do
        
        it 'works with default factory' do
          expect{ Father.one :factory }.to change(Father, :count).by(1)
        end
        
        it 'works with passing factory' do
          expect{ Father.one :factory, :another_father }.to change(Father, :count).by(1)
        end              
        
      end
      
      describe 'returns the newly created object' do
        
        it 'works with default factory' do
          returned = Father.one :factory
          returned.class.should == Father
          returned.should == Father.last
        end
        
        it 'works with passing factory' do          
          returned = Father.one :factory, :another_father
          returned.class.should == Father
          returned.should == Father.last
        end
        
      end
      
    end       
       
    it 'work with default arguments' do
      expect{ Father.one }.to change(Father, :count).by(1)
    end
    
  end
  
  describe 'second, third, fourth, fifth, sixth, seventh, eighth, ninth, tenth methods' do
      
    it 'returns 2st object when calling second' do
      
      Father.create_10
      
      Father.second.should   == Father.first(2).last
      
      Father.third.should    == Father.first(3).last
      
      Father.fourth.should   == Father.first(4).last
      
      Father.fifth.should    == Father.first(5).last
      
      Father.sixth.should    == Father.first(6).last
      
      Father.seventh.should  == Father.first(7).last
      
      Father.eighth.should   == Father.first(8).last
      
      Father.ninth.should    == Father.first(9).last
      
      Father.tenth.should    == Father.first(10).last
      
    end
    
  end
  
  describe 'when calls a non-defined method' do
    it 'raises NoMethodError' do
      expect {Father.non_existing_method}.to raise_exception(NoMethodError)
    end
  end
  
  describe 'random_update_n_associates method' do
    
    it 'update n associate objects' do
      father = Father.one
      father.has_4_children           
      father.random_update_2_children name:'updated_name'
      father.children.where(:name => 'updated_name').count.should == 2      
    end
    
    it 'update n associate objects randomly' do
      
      father = Father.one
      
      updated_indexes = []
            
      10.times do        
        father.has_4_children
        father.random_update_2_children(name:'updated_name')
        father.children.order('id asc').each_with_index do |child, index|
          updated_indexes << index if child.name == 'updated_name'
        end
      end      
      
      updated_indexes.flatten.uniq.sort.should == [0,1,2,3]
      
    end
    
  end
  
  describe 'serial_update method' do
    
    it 'update objects of the calling class serially' do
      
      5.Fathers
      Father.serial_update :number => [0,1,2,3], :name => ['zero', 'one', 'two']
      
      Father.first.number.should   == 0
      Father.second.number.should  == 1
      Father.third.number.should   == 2
      Father.fourth.number.should  == 3      
      
      Father.first.name.should     == 'zero'
      Father.second.name.should    == 'one'
      Father.third.name.should    == 'two'
      
    end
    
  end
  
  def assert_array_of_children(arr, item_count)
    arr.count.should be_equal(item_count)
    arr.each do |item|
      item.class.should == Child
    end
  end
    
end