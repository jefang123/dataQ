require_relative 'db_connection'
require_relative 'dataq_object'

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