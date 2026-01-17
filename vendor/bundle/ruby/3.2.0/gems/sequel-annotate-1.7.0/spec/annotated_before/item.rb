# Table: items
# Columns:
#  id                    | integer               | PRIMARY KEY DEFAULT nextval('items_id_seq'::regclass)
#  category_id           | integer               | NOT NULL
#  manufacturer_name     | character varying(50) |
#  manufacturer_location | text                  |
#  in_stock              | boolean               | DEFAULT false
#  name                  | text                  | DEFAULT 'John'::text
#  price                 | double precision      | DEFAULT 0
# Indexes:
#  items_pkey        | PRIMARY KEY btree (id)
#  name              | UNIQUE btree (manufacturer_name, manufacturer_location)
#  manufacturer_name | btree (manufacturer_name)
# Check constraints:
#  pos_id | (id > 0)
# Foreign key constraints:
#  items_category_id_fkey       | (category_id) REFERENCES categories(id)
#  items_manufacturer_name_fkey | (manufacturer_name, manufacturer_location) REFERENCES manufacturers(name, location)
# Triggers:
#  valid_price | BEFORE INSERT OR UPDATE ON items FOR EACH ROW EXECUTE PROCEDURE valid_price()

class Item < Sequel::Model
end
