require_relative 'db'

version = if DB.tables.include?(:schema_migrations)
  DB[:schema_migrations].order(:filename).last
elsif DB.tables.include?(:schema_info)
  DB[:schema_info].first[:version]
else
  0
end

puts version