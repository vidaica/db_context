require File.join( File.dirname(__FILE__), '..', 'rspec_helper' )

describe Fixnum do
  
  describe 'active_record_creating' do
    
    it 'delegates to ActiveRecord::create_n_instances' do
      expect(Father).to receive(:create_3).with(:import, :skip_validation, :factory => [:another_father, :white, :complexion => 'black'])
      3.Father(:import, :skip_validation, :factory => [:another_father, :white, :complexion => 'black'])
    end
    
    it 'returns the newly created instances' do
      returned = 3.Father
      expect(returned.count).to be 3
      returned.each{|item| expect(item).to be_instance_of Father }
    end
    
    it 'accepts plural form of class name' do
      returned = 3.Fathers
      expect(returned.count).to be 3
      returned.each{|item| expect(item).to be_instance_of Father }
    end
  
  end
    
end  