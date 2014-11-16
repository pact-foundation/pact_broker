module PactBroker
  module MigrationHelper

    extend self

    def large_text_type
      if Sequel::Model.db.adapter_scheme == :postgres
        :text
      else
        # Assume mysql
        :mediumtext
      end
    end
  end
end
