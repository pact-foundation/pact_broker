# To reduce the noise of the SQL logs, this class changes INFO
# logs to DEBUG, and changes the ERROR logs that occur when
# Sequel doesn't know if a table/view exists or not to DEBUG,
# so that they don't freak newbies out when they start up the
# broker for the first time.

require "delegate"

module PactBroker
  module DB
    class LogQuietener < SimpleDelegator
      def error *args
        if error_is_about_table_not_existing?(args)
          __getobj__().debug(*reassure_people_that_this_is_expected(args))
        elsif foreign_key_error?(args)
          __getobj__().warn(*args)
        else
          __getobj__().error(*args)
        end
      end

      def error_is_about_table_not_existing?(args)
        args.first.is_a?(String) &&
          ( args.first.include?("PG::UndefinedTable") ||
            args.first.include?("no such table") ||
            args.first.include?("no such view"))
      end

      # Foreign key exceptions are almost always transitory and unreproducible by this stage
      def foreign_key_error?(args)
        args.first.is_a?(String) && args.first.downcase.include?("foreign key")
      end

      def reassure_people_that_this_is_expected(args)
        message = args.shift
        message = message + " Don't panic. This happens when Sequel doesn't know if a table/view exists or not."
        [message] + args
      end
    end
  end
end
