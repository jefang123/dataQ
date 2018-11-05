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
  ```
  Cat.columns 

  =>[:id, :name, :owner_id]
  ```

* Class.where(params) - Returns filtered results based on params of Class
  ```
  Cat.where(:id => 1)

  => Cat @attributes={:id=>1, :name=>"Breakfast", :owner_id=>1}
  ```



### Specific Associations

  ```
  class Cat < DataQObject
    belongs_to :human, foreign_key: :owner_id
    has_one_through :home, :human, :house
  end

  class Human < DataQObject
    has_many :cats, foreign_key: :owner_id
    belongs_to :house
  end 

  class House < DataQObject
    has_many :humans
  end 
  ```

#### Cat 

* Cat.first.human 
* Cat.first.home 

#### Human 

* Human.first.cats
* Human.first.house 

#### House 

* House.first.humans
  

