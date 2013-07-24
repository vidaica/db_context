require File.join( File.dirname(__FILE__), '..', 'rspec_helper' )

describe Fixnum do
  
  describe 'active_record_creating' do
    
    describe 'create_method is :import' do
      
      describe 'create right number of objects for the right class' do
        
        it 'works without a factory' do        
          expect{ 3.Father :import }.to change(Father, :count).by(3)
        end
        
        it 'works with a factory' do
          expect{ 3.Father :import, :another_father }.to change(Father, :count).by(3)
        end
        
      end
      
      describe 'returns an array of newly created objects' do
        
        it 'works with default factory' do
          returned = 3.Father :import
          returned.class.should == Array
          returned.map(&:id).should == Father.last(3).map(&:id)
        end
        
        it 'work with passing factory' do 
          returned = 3.Father :import, :another_father
          returned.class.should == Array
          returned.map(&:id).should == Father.last(3).map(&:id)
        end
        
      end
      
      it 'activates validation by default' do
        expect{ 3.Father :import, :invalid_father }.to raise_exception(FailedImportError)
      end
      
      it 'ignores validation if :validate option is set to false' do
        expect{ 3.Father :import, :invalid_father, :validate => false }.to change(Father, :count).by(3)
      end
                  
    end
    
    describe 'create_method is :factory' do
      
      describe 'create right number of objects for the right class' do
        
        it 'works with default factory' do
          expect{ 3.Father :factory }.to change(Father, :count).by(3)
        end
        it 'works with passing a factory' do
          expect{ 3.Father :factory, :another_father }.to change(Father, :count).by(3)
        end
        
      end
      
      describe 'returns an array of newly created objects' do
        
        it 'works with default factory' do
          returned = 3.Father :factory
          returned.class.should == Array
          returned.map(&:id).should == Father.last(3).map(&:id)
        end
      
        it 'works with passing factory' do
          returned = 3.Father :factory, :another_father
          returned.class.should == Array
          returned.map(&:id).should == Father.last(3).map(&:id)
        end
    
      end
      
    end        
        
    it 'works with default arguments' do
      expect{ 3.Father }.to change(Father, :count).by(3)
    end
    
    it 'works with plural form of class name' do
      expect{ 3.Fathers }.to change(Father, :count).by(3)
    end
    
  end
  
  
  
end  