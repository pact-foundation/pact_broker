module PactBroker
  module Config
    class Setting < Sequel::Model(:config)
    end

    Setting.plugin :timestamps, update_on_create: true
  end
end

# Table: config
# Columns:
#  id         | integer                     | PRIMARY KEY DEFAULT nextval('config_id_seq'::regclass)
#  name       | text                        | NOT NULL
#  type       | text                        | NOT NULL
#  value      | text                        |
#  created_at | timestamp without time zone | NOT NULL
#  updated_at | timestamp without time zone | NOT NULL
# Indexes:
#  config_pkey       | PRIMARY KEY btree (id)
#  config_name_index | UNIQUE btree (name)
