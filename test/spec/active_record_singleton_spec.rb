require File.join( File.dirname(__FILE__), '..', 'rspec_helper' )

describe ActiveRecord::Base do
  
  describe 'has method' do
    
    before :each do      
      @father_data = [{:name => 'father1'}, {:name => 'father2'}, {:name => 'father3'}]              
    end
        
    shared_examples_for 'a good insertion method for ActiveRecord::has' do |insertion_method|
          
      it 'creates instances correctly' do      
        Father.has @father_data, insertion_method      
        Father.all.map(&:name).should == @father_data.map{|item| item[:name]}      
      end           
      
      it 'works with an explicit factory' do
        Father.has @father_data, insertion_method, :factory => :another_father
        Father.all.map(&:nickname).uniq.should eq ['Another Nick']
      end         
      
      it 'returns the newly created instances' do              
        returned = Father.has @father_data, insertion_method      
        returned.count.should be @father_data.count
        returned.each{|item| item.should be_instance_of Father}
      end
    
    end
          
    describe 'using activerecord_import for database insertion' do
      
      it 'uses activerecord_import for database insertion by default' do        
        Father.should_receive(:create_instances_by_import)
        Father.has @father_data 
      end
      
      it 'activates validation by default' do
        expect{ Father.has [{:name => ''}] }.to raise_exception(DbContext::FailedImportError)
      end
      
      it 'ignores validation with :skip_validation directive' do
        expect{ Father.has [{:name => ''}], :skip_validation }.not_to raise_exception(DbContext::FailedImportError)
      end
                 
      it_should_behave_like 'a good insertion method for ActiveRecord::has' 
      
    end
    
    describe 'using factory_girl for database insertion' do
      
      it 'uses factory_girl for database insertion with :girl directive' do        
        Father.should_receive(:create_instances_by_factory_girl)
        Father.has @father_data, :girl
      end
      
      it_should_behave_like 'a good insertion method for ActiveRecord::has', :girl
      
    end
           
  end
    
  describe 'create_n_instances method' do       
       
    shared_examples_for 'a good insertion method for ActiveRecord::create_n_instances' do |insertion_method|
          
      it 'creates n instances' do      
        expect{ Father.create_3 insertion_method }.to change(Father, :count).by(3)
      end                                      
           
      it 'works with an explicit factory' do
        returned = Father.create_3 insertion_method, :factory => :another_father           
        returned.count.should be 3
        returned.map(&:name).uniq.should == ['Another Father']
      end
      
      it 'returns array of newly created instances' do
        returned = Father.create_3 insertion_method
        returned.count.should be 3
        returned.each{|item| item.should be_an_instance_of Father }
      end           
    
    end
          
    describe 'using activerecord_import for database insertion' do
      
      it 'uses activerecord_import for database insertion by default' do        
        Father.should_receive(:create_instances_by_import)
        Father.create_3
      end
      
      it 'activates validation by default' do
        expect{ Father.create_3 :factory => :invalid_father }.to raise_exception(DbContext::FailedImportError)
      end
      
      it 'ignores validation with :skip_validation directive' do
        expect{ Father.create_3 :skip_validation, :factory => :invalid_father }.not_to raise_exception(DbContext::FailedImportError)
      end
                 
      it_should_behave_like 'a good insertion method for ActiveRecord::create_n_instances' 
      
    end
    
    describe 'using factory_girl for database insertion' do
      
      it 'uses factory_girl for database insertion with :girl directive' do        
        Father.should_receive(:create_instances_by_factory_girl)
        Father.create_3 :girl
      end
      
      it_should_behave_like 'a good insertion method for ActiveRecord::create_n_instances', :girl
      
    end
           
  end 
    
  describe 'one method' do
    
    it 'delegates to ActiveRecord::create_n_instances' do
      Father.should_receive(:create_1).with(:import, :skip_validation, :factory => :another_father).and_return([])
      Father.one(:import, :skip_validation, :factory => :another_father)
    end
    
    it 'returns the newly created instance' do
      Father.one.should be_instance_of Father
    end
       
    it 'uses factory_girl for database insertion by default' do
      Father.should_receive(:create_instances_by_factory_girl).and_return([])
      Father.one
    end
    
    it 'uses activerecord_import for database insertion with :import directive' do
      Father.should_receive(:create_instances_by_import).and_return([])
      Father.one :import
    end
    
  end
  
  describe 'second, third, fourth, fifth, sixth, seventh, eighth, ninth, tenth methods' do
      
    it 'returns 2st object when calling second' do
      
      Father.create_10
      
      Father.second.should   eq Father.first(2).last
      
      Father.third.should    eq Father.first(3).last
      
      Father.fourth.should   eq Father.first(4).last
      
      Father.fifth.should    eq Father.first(5).last
      
      Father.sixth.should    eq Father.first(6).last
      
      Father.seventh.should  eq Father.first(7).last
      
      Father.eighth.should   eq Father.first(8).last
      
      Father.ninth.should    eq Father.first(9).last
      
      Father.tenth.should    eq Father.first(10).last
      
    end
    
  end
  
  describe 'serial_update method' do
    
    it 'updates objects of the caller serially' do
      
      5.times{ FactoryGirl.create :father }
      
      Father.serial_update :number => [0,1,2,3], :name => ['zero', 'one', 'two']
      
      Father.first.number.should   be 0
      Father.second.number.should  be 1
      Father.third.number.should   be 2
      Father.fourth.number.should  be 3
      
      Father.first.name.should     eq 'zero'
      Father.second.name.should    eq 'one'
      Father.third.name.should     eq 'two'
      
    end
    
  end
  
  describe 'a non-defined method is called' do
    it 'raises NoMethodError' do
      expect {Father.non_existing_method}.to raise_exception(NoMethodError)
    end
  end
    
end  
  