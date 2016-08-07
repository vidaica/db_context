require File.join( File.dirname(__FILE__), '..', 'rspec_helper' )

describe ActiveRecord::Base do
  
  describe 'one method' do
    
    it 'delegates to ActiveRecord::create_n_instances' do
      expect(Father).to receive(:create_1).with(:import, :skip_validation, :factory => [:another_father, :white, :complexion => 'black']).and_return([])
      Father.one(:import, :skip_validation, :factory => [:another_father, :white, :complexion => 'black'])
    end
    
    it 'returns the newly created instance' do
      expect(Father.one).to be_instance_of Father
    end
       
    it 'uses factory_girl for database insertion by default' do
      expect(Father).to receive(:create_instances_by_factory_girl).and_return([])
      Father.one
    end
    
    it 'uses activerecord_import for database insertion with :import directive' do
      expect(Father).to receive(:create_instances_by_import).and_return([])
      Father.one :import
    end
    
  end
  
  
  describe 'has method' do
    
    before :each do      
      @father_data = [{:name => 'father1'}, {:name => 'father2'}, {:name => 'father3'}]              
    end
        
    shared_examples_for 'a good insertion method for ActiveRecord::has' do |insertion_method|
          
      it 'creates instances correctly' do      
        Father.has @father_data, insertion_method      
        expect(Father.all.map(&:name)).to eq @father_data.map{|item| item[:name]}      
      end           
      
      it 'works with an explicit factory' do
        Father.has @father_data, insertion_method, :factory => :another_father
        expect(Father.all.map(&:nickname).uniq).to eq ['Another Nick']
      end
      
      it 'supports factory_girl traits' do
        Father.has @father_data, insertion_method, :factory => [:father, :white]
        expect(Father.all.map(&:complexion).uniq).to eq ['white']
      end
      
      it 'supports attribute values in factory' do
        Father.has @father_data, insertion_method, :factory => [:father, :white, :complexion => 'black']
        expect(Father.all.map(&:complexion).uniq).to eq ['black']
      end
      
      it 'makes values in provided data overide values in factory' do
        @father_data.each{|item| item[:complexion] = 'yellow'}
        Father.has @father_data, insertion_method, :factory => [:father, :white, :complexion => 'black']
        expect(Father.all.map(&:complexion).uniq).to eq ['yellow']
      end
      
      it 'returns the newly created instances' do              
        returned = Father.has @father_data, insertion_method      
        expect(returned.count).to be @father_data.count
        returned.each{|item| expect(item).to be_instance_of Father}
      end
    
    end
          
    describe 'using activerecord_import for database insertion' do
      
      it 'uses activerecord_import for database insertion by default' do        
        expect(Father).to receive(:create_instances_by_import)
        Father.has @father_data 
      end
      
      it 'activates validation by default' do
        expect{ Father.has [{:name => ''}] }.to raise_exception(DbContext::FailedImportError)
      end
      
      it 'ignores validation with :skip_validation directive' do
        expect{ Father.has [{:name => ''}], :skip_validation }.not_to raise_error
      end
                 
      it_should_behave_like 'a good insertion method for ActiveRecord::has' 
      
    end
    
    describe 'using factory_girl for database insertion' do
      
      it 'uses factory_girl for database insertion with :girl directive' do        
        expect(Father).to receive(:create_instances_by_factory_girl)
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
        expect(returned.count).to be 3
        expect(returned.map(&:name).uniq).to eq ['Another Father']
      end
      
      it 'supports factory_girl traits' do
        Father.create_3 insertion_method, :factory => [:father, :white]
        expect(Father.all.map(&:complexion).uniq).to eq ['white']
      end
      
      it 'supports attribute values in factory' do
        Father.create_3 insertion_method, :factory => [:father, :white, :complexion => 'black']
        expect(Father.all.map(&:complexion).uniq).to eq ['black']
      end          
      
      it 'returns array of newly created instances' do
        returned = Father.create_3 insertion_method
        expect(returned.count).to be 3
        returned.each{|item| expect(item).to be_an_instance_of Father }
      end           
    
    end
          
    describe 'using activerecord_import for database insertion' do
      
      it 'uses activerecord_import for database insertion by default' do        
        expect(Father).to receive(:create_instances_by_import)
        Father.create_3
      end
      
      it 'activates validation by default' do
        expect{ Father.create_3 :factory => :invalid_father }.to raise_error(DbContext::FailedImportError)
      end
      
      it 'ignores validation with :skip_validation directive' do
        expect{ Father.create_3 :skip_validation, :factory => :invalid_father }.not_to raise_error
      end
                 
      it_should_behave_like 'a good insertion method for ActiveRecord::create_n_instances' 
      
    end
    
    describe 'using factory_girl for database insertion' do
      
      it 'uses factory_girl for database insertion with :girl directive' do        
        expect(Father).to receive(:create_instances_by_factory_girl)
        Father.create_3 :girl
      end
      
      it_should_behave_like 'a good insertion method for ActiveRecord::create_n_instances', :girl
      
    end
           
  end 
    
  
  describe 'second, third, fourth, fifth, sixth, seventh, eighth, ninth, tenth methods' do
      
    it 'returns 2st object when calling second' do
      
      Father.create_10
      
      expect(Father.second).to   eq Father.first(2).last
      
      expect(Father.third).to    eq Father.first(3).last
      
      expect(Father.fourth).to   eq Father.first(4).last
      
      expect(Father.fifth).to    eq Father.first(5).last
      
      expect(Father.sixth).to    eq Father.first(6).last
      
      expect(Father.seventh).to  eq Father.first(7).last
      
      expect(Father.eighth).to   eq Father.first(8).last
      
      expect(Father.ninth).to    eq Father.first(9).last
      
      expect(Father.tenth).to    eq Father.first(10).last
      
    end
    
  end
  
  describe 'serial_update method' do
    
    it 'updates objects of the caller serially' do
      
      5.times{ FactoryGirl.create :father }
      
      Father.serial_update :number => [0,1,2,3], :name => ['zero', 'one', 'two']
      
      expect(Father.first.number).to   be 0
      expect(Father.second.number).to  be 1
      expect(Father.third.number).to   be 2
      expect(Father.fourth.number).to  be 3
      
      expect(Father.first.name).to     eq 'zero'
      expect(Father.second.name).to    eq 'one'
      expect(Father.third.name).to     eq 'two'
      
    end
    
  end
  
  describe 'a method' do
    
    it 'loads all objects into an array' do
      
      5.times{ FactoryGirl.create :father }
      expect(Father.a.map(&:id).sort).to eq Father.all.to_a.map(&:id).sort
      
    end
    
  end
  
  describe 'a non-defined method is called' do
    it 'raises NoMethodError' do
      expect {Father.non_existing_method}.to raise_exception(NoMethodError)
    end
  end
    
end  
  