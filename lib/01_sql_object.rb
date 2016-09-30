require_relative 'db_connection'
require 'active_support/inflector'
require_relative 'validator'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
    @columns ||= DBConnection.execute2(
      "SELECT * FROM #{self.table_name}"
    ).first.map(&:to_sym)
  end

  def self.finalize!
    columns.each do |col|
      define_method("#{col}=") do |obj|
        attributes[col] = obj
      end

      define_method(col) do
        attributes[col]
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.to_s.tableize
    # ...
  end

  def self.all
    results = DBConnection.execute(<<-SQL
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
    SQL
    )
    parse_all(results)
  end

  def self.parse_all(results)
    results.map do |row|
      self.new(row)
    end
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        #{table_name}.id = ?
    SQL
    results.first && self.new(results.first)
  end

  def initialize(params = {})
    params.each do |k, v|
      begin
        send("#{k}=", v)
      rescue NoMethodError
        raise ArgumentError, "unknown attribute '#{k}'"
      end
    end
  end

  def attributes
    @attributes ||= Hash.new
  end

  def attribute_values
    self.class.columns.map { |name| send(name) }
  end

  def insert
    cols = self.class.columns.map(&:to_s)
    q_marks = "(#{cols.map { '?' }.join(', ')})"
    attrs = "(#{cols.join(', ')})"
    query = <<-SQL
      INSERT INTO
        #{self.class.table_name} #{attrs}
      VALUES
        #{q_marks}

    SQL
    DBConnection.execute(query, *attribute_values)
    self.id = DBConnection.last_insert_row_id
  end

  def update
    cols = self.class.columns.map(&:to_s)
    setters = cols.map {|col| "#{col} = ?"}.join(', ')
    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{setters}
      WHERE
        id = ?
    SQL
  end

  def save
    if respond_to?(:valid?)
      return false unless send(:valid?)
    end
    if self.id.nil?
      insert
    else
      update
    end
    true
  end

  def ==(obj)
    return true if eql?(obj)
    return false unless obj.is_a?(self.class) && obj.id
    return self.class.columns.all? do |col|
      self.send(col) == obj.send(col)
    end
  end
end
