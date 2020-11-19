module PactBroker
  module DB
    class CleanTask < ::Rake::TaskLib

      attr_accessor :database_connection
      attr_accessor :keep

      def initialize &block
        rake_task &block
      end

      def rake_task &block
        namespace :pact_broker do
          namespace :db do
            desc "Clean unnecessary pacts and verifications from database"
            task :clean do | t, args |

              instance_eval(&block)

              require 'pact_broker/db/clean'
              require 'pact_broker/matrix/unresolved_selector'
              require 'yaml'

              keep_selectors = nil
              if keep
                keep_selectors = [*keep].collect do | hash |
                  PactBroker::Matrix::UnresolvedSelector.new(hash)
                end
              end
              # TODO time it
              results = PactBroker::DB::Clean.call(database_connection, keep: keep_selectors)
              puts results.to_yaml
            end
          end
        end
      end
    end
  end
end