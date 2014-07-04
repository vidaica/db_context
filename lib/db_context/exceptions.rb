module DbContext
  
  class FailedImportError < Exception
  end
  
  class InvalidCreateMethod < Exception
  end
  
  class InvalidFactoryType < Exception
  end
    
  class NonExistentRelationship < Exception
  end
  
  class HasManyRelationshipExpected < Exception
  end
  
  class BelongsToRelationshipExpected < Exception
  end

end