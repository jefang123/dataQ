require_relative 'searchable'
require_relative 'dataq_object'
require 'active_support/inflector'


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
end


# Proof of concept: 

# Database 

# -> All -> show all things in db

# ->find(id)

# -> insert

# -> update 

# -> save

# -> where

# -> belongs_to

# -> has_many

# -> has_one_through

