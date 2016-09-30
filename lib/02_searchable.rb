require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_snippets = []
    where_args = []
    params.each do |k, v|
      where_args << v
      where_snippets << "#{k} = ?"
    end
    results = DBConnection.execute(<<-SQL, *where_args)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
      WHERE
        #{where_snippets.join(' AND ')}
    SQL
    parse_all(results)
  end
end

class SQLObject
  extend Searchable
end
