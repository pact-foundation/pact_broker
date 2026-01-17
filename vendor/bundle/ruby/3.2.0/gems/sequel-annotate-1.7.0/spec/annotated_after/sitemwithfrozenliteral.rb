# frozen_string_literal: true

class SItemWithFrozenLiteral < Sequel::Model(SDB[:items])
end

# Table: items
# Columns:
#  id                    | integer          | PRIMARY KEY AUTOINCREMENT
#  category_id           | integer          | NOT NULL
#  manufacturer_name     | varchar(50)      |
#  manufacturer_location | varchar(255)     |
#  in_stock              | boolean          | DEFAULT 0
#  name                  | varchar(255)     | DEFAULT 'John'
#  price                 | double precision | DEFAULT 0
# Indexes:
#  manufacturer_name | (manufacturer_name)
#  name              | UNIQUE (manufacturer_name, manufacturer_location)
# Foreign key constraints:
#  (category_id) REFERENCES categories
#  (manufacturer_name, manufacturer_location) REFERENCES manufacturers
