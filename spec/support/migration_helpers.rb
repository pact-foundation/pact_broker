require 'tasks/database'

module MigrationHelpers
  def create table_name, params, id_column_name = :id
    database[table_name].insert(params);
    database[table_name].order(id_column_name).last
  end

  def clean table_name
    database[table_name].delete rescue puts "Error cleaning #{table_name} #{$!}"
  end

  def database
    @database ||= DB.connection_for_env 'test'
  end
end
