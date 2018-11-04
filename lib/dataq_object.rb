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


class Cat < DataQObject
end

Cat.finalize!


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

class DataQObject
  extend Searchable
end