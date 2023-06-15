module PactBroker
  module Repositories
    module Helpers

      extend self

      def name_like column_name, value
        if PactBroker.configuration.use_case_sensitive_resource_names
          if mysql?
            # sigh, mysql, this is the only way to perform a case sensitive search
            Sequel.like(column_name, value.gsub("_", "\\_"), { case_insensitive: false })
          else
            { column_name => value }
          end
        else
          Sequel.like(column_name, value.gsub("_", "\\_"), { case_insensitive: true })
        end
      end

      def mysql?
        Sequel::Model.db.adapter_scheme.to_s =~ /mysql/
      end



      def postgres?
        Sequel::Model.db.adapter_scheme.to_s =~ /postgres/
      end
    end
  end
end
