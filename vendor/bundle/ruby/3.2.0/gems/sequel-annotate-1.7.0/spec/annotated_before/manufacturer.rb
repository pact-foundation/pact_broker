# Table: manufacturers
# Primary Key: (name, location)
# Columns:
#  name     | text |
#  location | text |
# Indexes:
#  manufacturers_pkey | PRIMARY KEY btree (name, location)
# Referenced By:
#  items | items_manufacturer_name_fkey | (manufacturer_name, manufacturer_location) REFERENCES manufacturers(name, location)

class Manufacturer < ABC
end
