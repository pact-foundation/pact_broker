require 'pact_broker/repositories/helpers'
require 'pact_broker/matrix/row'
require 'pact_broker/matrix/latest_row'

module PactBroker
  module Matrix
    class Repository
      include PactBroker::Repositories::Helpers
      include PactBroker::Repositories

      # TODO SORT BY MOST RECENT FIRST
      # TODO move latest verification logic in to database

      GROUP_BY_PROVIDER_VERSION_NUMBER = [:consumer_name, :consumer_version_number, :provider_name, :provider_version_number]
      GROUP_BY_PROVIDER = [:consumer_name, :consumer_version_number, :provider_name]
      GROUP_BY_PACT = [:consumer_name, :provider_name]

      # Return the latest matrix row (pact/verification) for each consumer_version_number/provider_version_number
      def find selectors, options = {}
        # The group with the nil provider_version_numbers will be the results of the left outer join
        # that don't have verifications, so we need to include them all.
        lines = find_all(selectors, options)
        lines = apply_scope(options, selectors, lines)

        if options.key?(:success)
          lines = lines.select{ |l| options[:success].include?(l.success) }
        end

        lines.sort.collect(&:values)
      end

      def all_versions_specified? selectors
        selectors.all?{ |s| s[:pacticipant_version_number] }
      end

      def apply_scope options, selectors, lines
        return lines unless options[:latestby] == 'cvp' || options[:latestby] == 'cp'

        group_by_columns = case options[:latestby]
        when 'cvp' then GROUP_BY_PROVIDER
        when 'cp' then GROUP_BY_PACT
        end

        lines.group_by{|line| group_by_columns.collect{|key| line.send(key) }}
          .values
          .collect{ | lines | lines.first.provider_version_number.nil? ? lines : lines.last }
          .flatten
      end

      def find_for_consumer_and_provider pacticipant_1_name, pacticipant_2_name
        selectors = [{ pacticipant_name: pacticipant_1_name }, { pacticipant_name: pacticipant_2_name }]
        find_all(selectors, {latestby: 'cvpv'}).sort.collect(&:values)
      end

      def find_compatible_pacticipant_versions selectors
        find(selectors, latestby: 'cvpv')
          .select{|line| line[:success] }
      end

      ##
      # If the version is nil, it means all versions for that pacticipant are to be included
      #
      def find_all selectors, options
        selectors = look_up_versions_for_tags(selectors)
        query = base_table(options).select_all

        if selectors.size == 1
          query = where_consumer_or_provider_is(selectors.first, query)
        else
          query = where_consumer_and_provider_in(selectors, query)
        end

        query = query.limit(options[:limit]) if options[:limit]

        query.order(:verification_executed_at, :verification_id).all
      end

      def base_table(options)
        return Row unless options[:latestby]
        return LatestRow
      end

      def look_up_versions_for_tags(selectors)
        selectors.collect do | selector |
          # resource validation currently stops tag being specified without latest=true
          if selector[:tag] && selector[:latest]
            version = version_repository.find_by_pacticpant_name_and_latest_tag(selector[:pacticipant_name], selector[:tag])
            # validation in resource should ensure we always have a version
            {
              pacticipant_name: selector[:pacticipant_name],
              pacticipant_version_number: version.number
            }
          elsif selector[:latest]
            version = version_repository.find_latest_by_pacticpant_name(selector[:pacticipant_name])
            {
              pacticipant_name: selector[:pacticipant_name],
              pacticipant_version_number: version.number
            }
          else
            selector
          end
        end
      end

      def where_consumer_and_provider_in selectors, query
          query.where{
            Sequel.&(
              Sequel.|(
                *selectors.collect{ |s| s[:pacticipant_version_number] ? Sequel.&(consumer_name: s[:pacticipant_name], consumer_version_number: s[:pacticipant_version_number]) :  Sequel.&(consumer_name: s[:pacticipant_name]) }
              ),
              Sequel.|(
                *(selectors.collect{ |s| s[:pacticipant_version_number] ? Sequel.&(provider_name: s[:pacticipant_name], provider_version_number: s[:pacticipant_version_number]) :  Sequel.&(provider_name: s[:pacticipant_name]) } +
                  selectors.collect{ |s| Sequel.&(provider_name: s[:pacticipant_name], provider_version_number: nil) })
              )
            )
          }
      end

      def where_consumer_or_provider_is s, query
        query.where{
          Sequel.|(
            s[:pacticipant_version_number] ? Sequel.&(consumer_name: s[:pacticipant_name], consumer_version_number: s[:pacticipant_version_number]) :  Sequel.&(consumer_name: s[:pacticipant_name]),
            s[:pacticipant_version_number] ? Sequel.&(provider_name: s[:pacticipant_name], provider_version_number: s[:pacticipant_version_number]) :  Sequel.&(provider_name: s[:pacticipant_name])
          )
        }
      end
    end
  end
end
