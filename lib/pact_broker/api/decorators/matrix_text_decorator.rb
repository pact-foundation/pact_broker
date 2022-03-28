require "ostruct"
require "table_print"
require "pact_broker/api/pact_broker_urls"
require "pact_broker/api/decorators/matrix_decorator"
require "pact_broker/versions/abbreviate_number"

module PactBroker
  module Api
    module Decorators
      class MatrixTextDecorator

        Line = Struct.new(:consumer, :consumer_version, :provider, :provider_version, :success, :ref, :ignored)

        def initialize(represented)
          @represented = represented
        end

        def to_text(options)
          json = PactBroker::Api::Decorators::MatrixDecorator.new(represented).to_json(options)
          matrix = JSON.parse(json, symbolize_names: true)
          matrix_rows = matrix[:matrix]
          return "" if matrix_rows.size == 0
          data = prepare_data(matrix_rows)
          printer = TablePrint::Printer.new(data, tp_options(data))
          printer.table_print + verification_result_urls_text(matrix)
        end

        private

        attr_reader :represented

        def prepare_data(matrix_rows)
          verification_result_number = 0
          matrix_rows.each_with_index.collect do | line |
            has_verification_result_url = lookup(line, nil, :verificationResult, :_links, :self, :href)
            if has_verification_result_url
              verification_result_number += 1
            end
            Line.new(
              lookup(line, "???", :consumer, :name),
              PactBroker::Versions::AbbreviateNumber.call(lookup(line, "???", :consumer, :version, :number)),
              lookup(line, "???", :provider, :name) ,
              PactBroker::Versions::AbbreviateNumber.call(lookup(line, "???", :provider, :version, :number)),
              (lookup(line, "???", :verificationResult, :success)).to_s + ( line[:ignored] ? " [ignored]" : ""),
              has_verification_result_url ? verification_result_number : "",
              lookup(line, nil, :ignored)
            )
          end
        end

        def tp_options(data)
          [
            { consumer: { width: max_width(data, :consumer, 'CONSUMER') } },
            { consumer_version: { display_name: 'C.VERSION', width: max_width(data, :consumer_version, 'C.VERSION') } },
            { provider: { width: max_width(data, :provider, 'PROVIDER') } },
            { provider_version: { display_name: 'P.VERSION', width: max_width(data, :provider_version, 'P.VERSION') } },
            { success: { display_name: 'SUCCESS?' } },
            { ref: { display_name: 'RESULT#' } }
          ]
        end

        def lookup line, default, *keys
          keys.reduce(line) { | line, key | line[key] }
        rescue NoMethodError
          default
        end

        def verification_results_urls_and_successes(matrix)
          (matrix[:matrix] || []).collect do | row |
            url = row.dig(:verificationResult, :_links, :self, :href)
            if url
              success = row.dig(:verificationResult, :success)
              [url, success]
            else
              nil
            end
          end.compact
        end

        def verification_result_urls_text(matrix)
          text = verification_results_urls_and_successes(matrix).each_with_index.collect do |(url, success), i|
            status = success ? 'success' : 'failure'
            "#{i+1}. #{url} (#{status})"
          end.join("\n")

          if text.size > 0
            "\n\nVERIFICATION RESULTS\n--------------------\n#{text}"
          else
            text
          end
        end

        def max_width(data, column, title)
          (data.collect{ |row| row.send(column) } + [title]).compact.collect(&:size).max
        end
      end
    end
  end
end
