module Approvals
  module Writers
    class HashWriter < TextWriter

      def format(data)
        lines = filter(data).map do |key, value|
          "\t#{key.inspect} => #{value.inspect}"
        end.join("\n")

        "{\n#{lines}\n}\n"
      end

      def filter data
        filter = ::Approvals::Filter.new(Approvals.configuration.excluded_json_keys)
        filter.apply(data)
      end

    end
  end
end
