require 'pact_broker/repositories/helpers'
require 'pact_broker/matrix/row'
require 'pact_broker/matrix/latest_row'
require 'pact_broker/matrix/head_row'
require 'pact_broker/error'


module PactBroker
  module Matrix

    class Error < PactBroker::Error; end

    class Repository
      include PactBroker::Repositories::Helpers
      include PactBroker::Repositories

      # TODO move latest verification logic in to database

      TP_COLS = PactBroker::Matrix::Row::TP_COLS

      GROUP_BY_PROVIDER_VERSION_NUMBER = [:consumer_name, :consumer_version_number, :provider_name, :provider_version_number]
      GROUP_BY_PROVIDER = [:consumer_name, :consumer_version_number, :provider_name]
      GROUP_BY_PACT = [:consumer_name, :provider_name]

      # Use a block when the refresh is caused by a resource deletion
      # This allows us to store the correct object ids for use afterwards
      def refresh params
        criteria = find_ids_for_pacticipant_names(params)
        yield if block_given?
        PactBroker::Matrix::Row.refresh(criteria)
        PactBroker::Matrix::HeadRow.refresh(criteria)
      end

      # Only need to update the HeadRow table when tags change
      # because it only changes which rows are the latest tagged ones -
      # it doesn't change the actual values in the underlying matrix.
      def refresh_tags params
        criteria = find_ids_for_pacticipant_names(params)
        yield if block_given?
        PactBroker::Matrix::HeadRow.refresh(criteria)
      end

      def find_ids_for_pacticipant_names params
        criteria  = {}

        if params[:consumer_name] || params[:provider_name]
          if params[:consumer_name]
            pacticipant = PactBroker::Domain::Pacticipant.where(name_like(:name, params[:consumer_name])).single_record
            criteria[:consumer_id] = pacticipant.id if pacticipant
          end

          if params[:provider_name]
            pacticipant = PactBroker::Domain::Pacticipant.where(name_like(:name, params[:provider_name])).single_record
            criteria[:provider_id] = pacticipant.id if pacticipant
          end
        end

        if params[:pacticipant_name]
          pacticipant = PactBroker::Domain::Pacticipant.where(name_like(:name, params[:pacticipant_name])).single_record
          criteria[:pacticipant_id] = pacticipant.id if pacticipant
        end

        criteria
      end

      # Return the latest matrix row (pact/verification) for each consumer_version_number/provider_version_number
      def find selectors, options = {}
        lines = query_matrix(resolve_selectors(selectors, options), options)
        lines = apply_latestby(options, selectors, lines)

        # This needs to be done after the latestby, so can't be done in the db unless
        # the latestby logic is moved to the db
        if options.key?(:success)
          lines = lines.select{ |l| options[:success].include?(l.success) }
        end

        lines.sort
      end



      def apply_latestby options, selectors, lines
        return lines unless options[:latestby]
        group_by_columns = case options[:latestby]
        when 'cvpv' then GROUP_BY_PROVIDER_VERSION_NUMBER
        when 'cvp' then GROUP_BY_PROVIDER
        when 'cp' then GROUP_BY_PACT
        end

        # The group with the nil provider_version_numbers will be the results of the left outer join
        # that don't have verifications, so we need to include them all.
        remove_overwritten_revisions(lines).group_by{|line| group_by_columns.collect{|key| line.send(key) }}
          .values
          .collect{ | lines | lines.first.provider_version_number.nil? ? lines : lines.first }
          .flatten
      end

      def remove_overwritten_revisions lines
        latest_revisions_keys = {}
        latest_revisions = []
        lines.each do | line |
          key = "#{line.consumer_name}-#{line.provider_name}-#{line.consumer_version_number}"
          if !latest_revisions_keys.key?(key) || latest_revisions_keys[key] == line.pact_revision_number
            latest_revisions << line
            latest_revisions_keys[key] ||= line.pact_revision_number
          end
        end
        latest_revisions
      end

      def find_for_consumer_and_provider pacticipant_1_name, pacticipant_2_name
        selectors = [{ pacticipant_name: pacticipant_1_name }, { pacticipant_name: pacticipant_2_name }]
        options = { latestby: 'cvpv' }
        find(selectors, options)
      end

      def find_compatible_pacticipant_versions selectors
        find(selectors, latestby: 'cvpv').select{|line| line.success }
      end

      def query_matrix selectors, options
        query = view_for(options).select_all.matching_selectors(selectors)
        query = query.limit(options[:limit]) if options[:limit]
        query
          .order_by_names_ascending_most_recent_first
          .eager(:consumer_version_tags)
          .eager(:provider_version_tags)
          .all
      end

      def view_for(options)
        Row
      end

      def resolve_selectors(selectors, options)
        selectors = look_up_versions_for_latest_and_tag(selectors, options)

        if options[:latest]
          apply_latest_and_tag_to_inferred_selectors(selectors, options)
        else
          selectors
        end
      end

      # Find the version number for selectors with the latest (tagged) version specified
      def look_up_versions_for_latest_and_tag(selectors, options)
        selectors.collect do | selector |
          # resource validation currently stops tag being specified without latest=true
          if selector[:tag] && selector[:latest]
            version = version_repository.find_by_pacticpant_name_and_latest_tag(selector[:pacticipant_name], selector[:tag])
            raise Error.new("Could not find version with tag #{selector[:tag].inspect} for #{selector[:pacticipant_name]}") unless version
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
            selector.dup
          end
        end.collect do | selector |
          if selector[:pacticipant_name]
            pacticipant = PactBroker::Domain::Pacticipant.find(name: selector[:pacticipant_name])
            selector[:pacticipant_id] = pacticipant ? pacticipant.id : nil
          end

          if selector[:pacticipant_name] && selector[:pacticipant_version_number]
            version = version_repository.find_by_pacticipant_name_and_number(selector[:pacticipant_name], selector[:pacticipant_version_number])
            selector[:pacticipant_version_id] = version ? version.id : nil
          end

          if selector[:pacticipant_version_number].nil?
            selector[:pacticipant_version_id] = nil
          end
          selector
        end
      end

      # eg. when checking to see if Foo version 2 can be deployed to prod,
      # need to look up all the 'partner' pacticipants, and determine their latest prod versions
      def apply_latest_and_tag_to_inferred_selectors(selectors, options)
        all_pacticipant_names = all_pacticipant_names_in_specified_matrix(selectors, options)
        specified_names = selectors.collect{ |s| s[:pacticipant_name] }
        inferred_names = all_pacticipant_names - specified_names

        inferred_selectors = inferred_names.collect do | pacticipant_name |
          {
            pacticipant_name: pacticipant_name,
            latest: options[:latest]
          }.tap { |it| it[:tag] = options[:tag] if options[:tag] }
        end

        selectors + look_up_versions_for_latest_and_tag(inferred_selectors, options)
      end

      def all_pacticipant_names_in_specified_matrix(selectors, options)
        query = view_for(options).select(:consumer_name, :provider_name)
        query = query.matching_selectors(selectors)
        query
          .all
          .collect{ | row | [row.consumer_name, row.provider_name] }
          .flatten
          .uniq
      end
    end
  end
end
