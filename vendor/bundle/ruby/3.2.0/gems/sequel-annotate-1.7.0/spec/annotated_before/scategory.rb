# Table: categories
# Columns:
#  id   | integer      | PRIMARY KEY AUTOINCREMENT
#  name | varchar(255) | NOT NULL
# Indexes:
#  categories_name_key | UNIQUE (name)

class SCategory < Sequel::Model(SDB[:categories])
end
