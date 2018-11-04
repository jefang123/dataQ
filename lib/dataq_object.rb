require_relative 'db_connection'
require 'active_support/inflector'

class DataQObject
  def self.columns
    return @columns if @columns 
    a = DBConnection.execute2(<<-SQL)
    SELECT 
      *
    FROM
      #{ self.table_name }
    SQL

    a.first.map! { |el| el.to_sym }

    @columns = a.first
  end

  def self.finalize!
    columns.each do |column|

      define_method(column) do 
        self.attributes[column]
      end
      
      define_method("#{ column }=") do |val|
        self.attributes[column] = val
      end 

    end 
  end

  def self.table_name=(table_name)
    instance_variable_set(:@table_name, table_name)
  end

  def self.table_name
    instance_variable_set(:@table_name, "#{ self.to_s.downcase }s")
  end

  def self.all
    a = DBConnection.execute(<<-SQL)
    SELECT 
      *
    FROM 
      #{ self.table_name }
    SQL

    self.parse_all(a)
  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end 
  end

  def self.find(id)
    a = DBConnection.execute(<<-SQL, id: id)
    SELECT 
      *
    FROM 
      #{ self.table_name }
    WHERE 
      id = :id 
    SQL

    return nil if a.empty?
    self.parse_all(a).first
  end

  def initialize(params = {})
    params.each do |key, value|
      unless self.class.columns.include?(key.to_sym)
        raise "Unknown Attribute '#{ key }'"
      end 
      self.send("#{ key }=" , value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.attributes.values
  end

  def insert
    new_id = self.class.all.length + 1 
    a = self.class.columns - [:id]
    col_names = a.join(",")
    question_marks = (["?"]*attributes_values.length).join(",")

    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO 
      #{self.class.table_name} (#{ col_names })
    VALUES 
      (#{ question_marks })
    SQL

    self.id = new_id 
  end

  def update
    col = self.class.columns.map{ |column| "#{ column } = ?"}.join(",")
    DBConnection.execute(<<-SQL, *attribute_values, id: self.id)
    UPDATE 
      #{ self.class.table_name }
    SET 
      #{ col }
    WHERE 
      id = :id
    SQL
  end

  def save
    if self.id.nil?
      insert 
    else 
      update 
    end
  end
end

module Searchable
  def where(params)
    where_line = params.map { |key, value| " #{key} = ? " }.join("AND")
    values = params.values
    
    a = DBConnection.execute(<<-SQL, *values)
      SELECT
        *
      FROM
        #{ self.table_name }
      WHERE
        #{ where_line }
    SQL

    return [] if a.empty?
    parse_all(a)
  end
end

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})

    defaults = {
      :foreign_key => "#{name}_id".to_sym,
      :primary_key => :id, 
      :class_name => name.camelize
    }

    defaults.keys.each do |key|
      self.send("#{ key }=", options[key] || defaults[key])
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
 
    defaults = {
      :foreign_key => "#{ self_class_name.downcase }_id".to_sym,
      :primary_key => :id, 
      :class_name => name.singularize.camelize
    }
    defaults.keys.each do |key|
      self.send("#{ key }=", options[key] || defaults[key])
    end
  end
end

module Associatable
  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)
    define_method(name) do 
      options = self.class.assoc_options[name]
      key_val = self.send(options.foreign_key)
      options 
        .model_class 
        .where(:id => key_val)
        .first
    end 
  end

  def has_many(name, options = {})
    self.assoc_options[name] = HasManyOptions.new(name, self, options)
    define_method(name) do 
      options = self.class.assoc_options[name]
      key_val = self.id
      options
        .model_class
        .where(options.foreign_key => key_val)
    end 
  end

  def assoc_options
    @assoc_options ||= {}
  end

  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]
      key_val = self.send(through_options.foreign_key)
      through = through_options
      .model_class
        .where(:id => key_val)
        .first
      through_key_val = through.send(source_options.foreign_key)
      source_options
      .model_class
        .where(:id => through_key_val)
        .first
    end 
  end
end


class DataQObject
  extend Associatable
  extend Searchable
end


class Cat < DataQObject
end

class Human < DataQObject
end 

class House < DataQObject
end 

Cat.finalize!
Human.finalize!
House.finalize!