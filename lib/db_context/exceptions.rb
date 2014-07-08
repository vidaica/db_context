module DbContext
  
  class FailedImportError < Exception
  end
  
  class InvalidCreateMethod < Exception
  end
  
  class InvalidFactoryType < Exception
  end
    
  class NonExistentAssociation < Exception
  end
  
  class HasManyAssociationExpected < Exception
  end
  
  class BelongsToAssociationExpected < Exception
  end

end