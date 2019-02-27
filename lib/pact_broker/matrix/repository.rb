require 'pact_broker/repositories/helpers'
require 'pact_broker/matrix/row'
require 'pact_broker/matrix/head_row'
require 'pact_broker/error'
require 'pact_broker/matrix/query_results'
require 'pact_broker/matrix/integration'
require 'pact_broker/matrix/query_results_with_deployment_status_summary'
require 'pact_broker/matrix/resolved_selector'

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

        criteria[:tag_name] = params[:tag_name] if params[:tag_name].is_a?(String) # Could be a sym from resource parameters in api.rb
        criteria
      end

      # Return the latest matrix row (pact/verification) for each consumer_version_number/provider_version_number
      def find specified_selectors, options = {}
        resolved_selectors = resolve_selectors(specified_selectors, options)
        lines = query_matrix(resolved_selectors, options)
        lines = apply_latestby(options, specified_selectors, lines)

        # This needs to be done after the latestby, so can't be done in the db unless
        # the latestby logic is moved to the db
        if options.key?(:success)
          lines = lines.select{ |l| options[:success].include?(l.success) }
        end

        QueryResults.new(lines.sort, specified_selectors, options, resolved_selectors)
      end

      def find_for_consumer_and_provider pacticipant_1_name, pacticipant_2_name
        selectors = [{ pacticipant_name: pacticipant_1_name }, { pacticipant_name: pacticipant_2_name }]
        options = { latestby: 'cvpv' }
        find(selectors, options)
      end

      def find_compatible_pacticipant_versions selectors
        find(selectors, latestby: 'cvpv').select{|line| line.success }
      end

      def find_integrations(pacticipant_names)
        selectors = pacticipant_names.collect{ | pacticipant_name | add_ids_to_selector(pacticipant_name: pacticipant_name) }
        Row
          .select(:consumer_name, :consumer_id, :provider_name, :provider_id)
          .matching_selectors(selectors)
          .distinct
          .all
          .collect do |row |
            row.to_hash
          end
          .uniq
          .collect do | hash |
            Integration.from_hash(hash.merge(required: pacticipant_names.include?(hash[:consumer_name])))
          end
      end

      private

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

      def resolve_selectors(specified_selectors, options)
        resolved_specified_selectors = resolve_versions_and_add_ids(specified_selectors, options)
        if options[:latest] || options[:tag]
          add_inferred_selectors(resolved_specified_selectors, options)
        else
          resolved_specified_selectors
        end
      end

      # Find the version number for selectors with the latest and/or tag specified
      def resolve_versions_and_add_ids(selectors, options, required = true)
        selectors.collect do | selector |
          pacticipant = PactBroker::Domain::Pacticipant.find(name: selector[:pacticipant_name])

          versions = find_versions_for_selector(selector, required)

          if versions
            versions.collect do | version |
              if version
                selector_for_version(pacticipant, version)
              else
                selector_for_non_existing_version(pacticipant)
              end
            end
          else
            selector_without_version(pacticipant)
          end
        end.flatten
      end

      def find_versions_for_selector(selector, required)
        if selector[:tag] && selector[:latest]
          version = version_repository.find_by_pacticipant_name_and_latest_tag(selector[:pacticipant_name], selector[:tag])
          # raise Error.new("No version of #{selector[:pacticipant_name]} found with tag #{selector[:tag]}") if required && !version
          [version]
        elsif selector[:latest]
          version = version_repository.find_latest_by_pacticpant_name(selector[:pacticipant_name])
          # raise Error.new("No version of #{selector[:pacticipant_name]} found") if required && !version
          [version]
        elsif selector[:tag]
          versions = version_repository.find_by_pacticipant_name_and_tag(selector[:pacticipant_name], selector[:tag])
          # raise Error.new("No version of #{selector[:pacticipant_name]} found with tag #{selector[:tag]}") if required && versions.empty?
          versions.any? ? versions : [nil]
        elsif selector[:pacticipant_version_number]
          version = version_repository.find_by_pacticipant_name_and_number(selector[:pacticipant_name], selector[:pacticipant_version_number])
          # raise Error.new("No version #{selector[:pacticipant_version_number]} of #{selector[:pacticipant_name]} found") if required && !version
          [version]
        else
          nil
        end
      end

      def add_ids_to_selector(selector)
        if selector[:pacticipant_name]
          pacticipant = PactBroker::Domain::Pacticipant.find(name: selector[:pacticipant_name])
          selector[:pacticipant_id] = pacticipant ? pacticipant.id : nil
        end

        if selector[:pacticipant_name] && selector[:pacticipant_version_number] && !selector[:pacticipant_version_id]
          version = version_repository.find_by_pacticipant_name_and_number(selector[:pacticipant_name], selector[:pacticipant_version_number])
          selector[:pacticipant_version_id] = version ? version.id : nil
        end

        if !selector.key?(:pacticipant_version_id)
           selector[:pacticipant_version_id] = nil
        end
        selector
      end

      # eg. when checking to see if Foo version 2 can be deployed to prod,
      # need to look up all the 'partner' pacticipants, and determine their latest prod versions
      def add_inferred_selectors(resolved_specified_selectors, options)
        integrations = find_integrations(resolved_specified_selectors.collect{|s| s[:pacticipant_name]})
        all_pacticipant_names = integrations.collect(&:pacticipant_names).flatten.uniq
        specified_names = resolved_specified_selectors.collect{ |s| s[:pacticipant_name] }
        inferred_pacticipant_names = all_pacticipant_names - specified_names
        # Inferred providers are required for a consumer to be deployed
        required_inferred_pacticipant_names = inferred_pacticipant_names.select{ | n | integrations.any?{ |i| i.involves_provider_with_name?(n) } }
        # Inferred consumers are NOT required for a provider to be deployed
        optional_inferred_pacticipant_names = inferred_pacticipant_names - required_inferred_pacticipant_names

        resolved_specified_selectors +
          build_inferred_selectors(required_inferred_pacticipant_names, options, true) +
          build_inferred_selectors(optional_inferred_pacticipant_names, options, false)
      end

      def build_inferred_selectors(inferred_pacticipant_names, options, required)
        selectors = inferred_pacticipant_names.collect do | pacticipant_name |
          selector = {
            pacticipant_name: pacticipant_name
          }
          selector[:tag] = options[:tag] if options[:tag]
          selector[:latest] = options[:latest] if options[:latest]
          selector
        end
        resolve_versions_and_add_ids(selectors, options, required)
      end

      def all_pacticipant_names_in_specified_matrix(selectors)
        find_integrations(selectors.collect{|s| s[:pacticipant_name]})
          .collect(&:pacticipant_names)
          .flatten
          .uniq
      end

      def selector_for_non_existing_version(pacticipant)
        ResolvedSelector.for_pacticipant_and_non_existing_version(pacticipant)
      end

      def selector_for_version(pacticipant, version)
        ResolvedSelector.for_pacticipant_and_version(pacticipant, version)
      end

      def selector_without_version(pacticipant)
        ResolvedSelector.for_pacticipant(pacticipant)
      end
    end
  end
end
