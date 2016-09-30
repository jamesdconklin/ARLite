require_relative '02_searchable'
require 'active_support/inflector'
require 'byebug'

# Phase IIIa
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
    name = name.to_s
    @foreign_key = options[:foreign_key] ||
                   ("#{name.underscore}_id".to_sym)
    @class_name = options[:class_name] ||
                  name.camelcase.singularize
    @primary_key = options[:primary_key] || :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    name = name.to_s
    self_class_name = self_class_name.to_s
    @foreign_key = options[:foreign_key] ||
                   ("#{self_class_name.underscore}_id".to_sym)
    @class_name = options[:class_name] ||
                  name.singularize.camelcase
    @primary_key = options[:primary_key] || :id
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options
    define_method(name) do
      foreign_value = self.send(options.foreign_key)
      assoc_class = options.model_class
      assoc_class.where(options.primary_key => foreign_value).first
    end
  end

  def has_many(name, options = {})
    # byebug
    options = HasManyOptions.new(name, self.to_s, options)
    define_method(name.to_sym) do
      primary_value = self.send(options.primary_key)
      assoc_class = options.model_class
      assoc_class.where(options.foreign_key => primary_value)
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
