# DataQ - Object-Relational Mapping for Rails 

DataQ connects classes to relational database tables(SQL3) to establish a persistence layer for applications. By providing a DataQObject class as a base class, DataQ can provide mapping between classes and an existing table in the database. Such classes are referred to as "Models", which can also be connected through *associations*

Features of DataQ are dependent on naming as it relies on class and assocition names to create mappings between database and models. 

## Instructions for use:
After downloading, run 
```
bundle install
``` 
to install required gems such as pry

In pry run 

```
pry(main) > load 'lib/dataq_object.rb'
``` 

A cats.sql file is provided for a default database. To set up the database manually run in command line:

``` 
cat cats.sql | sqlite3 cats.db
``` 

Current Classes in the database: 
  * Cat 
  * Human 
  * House

## Methods: 

* Class.all - Returns all objects in the database of Class 
* Class.first - Returns first object in the database of Class 
* Class.columns - Returns current columns in database of Class 
* Class.where(params) - Returns filtered results based on params of Class



* Specific Associations

  ```
  class Cat < DataQObject 
    belongs_to :owner
    has_one :home 
  end
  ```

  #### Current associations: 

    * belongs_to 
    * has_many 
    * has_one_through 


### Public API: 

* where(params) - Query that filters through database with given parameters.

  ```Cat.where(:owner_id => 1)``` 

