# DataQ - Object-Relational Mapping for Rails 

DataQ connects classes to relational database tables(SQL3) to establish a persistence layer for applications. By providing a DataQObject class as a base class, DataQ can provide mapping between classes and an existing table in the database. Such classes are referred to as "Models", which can also be connected through *associations*

Features of DataQ are dependent on naming as it relies on class and assocition names to create mappings between database and models. 

## Features: 

* Associations between objects can be defined by class methods 

  class Cat < DataQObject 
    belongs_to :owner
    has_one :home 
  end

  Current associations: 

    * belongs_to 
    * has_many 
    * has_one_through 


### Public API: 

* where(params) - Query that filters through database with given parameters.

  ```Cat.where(:owner_id => 1)``` 

