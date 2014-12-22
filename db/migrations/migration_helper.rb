module PactBroker
  module MigrationHelper

    extend self

    def large_text_type
      if adapter == 'postgres'
        :text
      else
        # Assume mysql
        :mediumtext
      end
    end

    def with_mysql
      if adapter =~ /mysql/
        yield
      end
    end

    def adapter
      Sequel::Model.db.adapter_scheme.to_s
    end
  end
end
