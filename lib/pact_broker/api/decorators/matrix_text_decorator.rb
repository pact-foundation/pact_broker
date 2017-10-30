require 'ostruct'
require 'pact_broker/api/pact_broker_urls'
require 'table_print'

module PactBroker
  module Api
    module Decorators
      class MatrixTextDecorator
        Line = Struct.new(:consumer, :consumer_version, :provider, :provider_version, :success)

        def initialize(lines)
          @lines = lines
        end

        def to_text(options)
          data = lines.collect do | line |
            Line.new(line[:consumer_name], line[:consumer_version_number], line[:provider_name], line[:provider_version_number], line[:success])
          end
          printer = TablePrint::Printer.new(data)
          printer.table_print + "\n"
        end

        private

        attr_reader :lines
      end
    end
  end
end
