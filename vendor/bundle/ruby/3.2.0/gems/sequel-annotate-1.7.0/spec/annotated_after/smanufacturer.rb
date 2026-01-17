class SManufacturer < Sequel::Model(SDB[:manufacturers])
end

# Table: manufacturers
# Primary Key: (name, location)
# Columns:
#  name     | varchar(255) |
#  location | varchar(255) |
