class Category < Sequel::Model
end

# Table: categories
# Columns:
#  id   | integer | PRIMARY KEY DEFAULT nextval('categories_id_seq'::regclass)
#  name | text    | NOT NULL
# Indexes:
#  categories_pkey     | PRIMARY KEY btree (id)
#  categories_name_key | UNIQUE btree (name)
# Referenced By:
#  items | items_category_id_fkey | (category_id) REFERENCES categories(id)
