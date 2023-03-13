require "ostruct"
require "pact_broker/api/pact_broker_urls"
require "pact_broker/api/decorators/matrix_decorator"

require "table_print"

module PactBroker
  module Api
    module Decorators
      class MatrixTextDecorator
        Line = Struct.new(:consumer, :c_version, :revision, :provider, :p_version, :number, :success)

        def initialize(lines)
          @lines = lines
        end

        def to_text(**_options)
          json_decorator = PactBroker::Api::Decorators::MatrixDecorator.new(lines)
          data = lines.collect do | line |
            Line.new(line.consumer_name, line.consumer_version_number, line.pact_revision_number, line.provider_name, line.provider_version_number, line.verification_number, line.success)
          end
          printer = TablePrint::Printer.new(data)
          printer.table_print + "\n\nDeployable: #{json_decorator.deployable.inspect}\nReason: #{json_decorator.reason}\n"
        end

        private

        attr_reader :lines
      end
    end
  end
end
