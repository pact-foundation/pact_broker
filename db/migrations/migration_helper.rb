module PactBroker
  module MigrationHelper

    extend self

    def large_text_type
      if postgres?
        :text
      else
        # Assume mysql
        :mediumtext
      end
    end

    def with_mysql
      if mysql?
        yield
      end
    end

    def mysql?
      adapter =~ /mysql/
    end

    def postgres?
      adapter == 'postgres'
    end

    def adapter
      Sequel::Model.db.adapter_scheme.to_s
    end

    def with_type_hash_if_postgres(options)
      if postgres?
        options.merge(type: "hash")
      else
        options
      end
    end

    def sqlite_safe string
      if adapter == 'sqlite'
        string.gsub(/(?:\b|")order(?:"|\b)/, '`order`')
      else
        string
      end
    end
  end
end
