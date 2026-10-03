module PactBroker
  module Matrix
    class RowIgnorer

      class << self
        # Splits the matrix rows into considered rows and ignored rows, based on the
        # ignore selectors specified by the user in the can-i-deploy command (eg. --ignore SomeProviderThatIsNotReadyYet).
        # @param [Array<MatrixRow, EveryRow>] rows
        # @param [<PactBroker::Matrix::ResolvedSelector>] resolved_ignore_selectors
        # @param [<PactBroker::Matrix::ResolvedSelector>] resolved_selectors the specified and inferred selectors for the query
        # @return [Array<MatrixRow, EveryRow>] considered_rows, [Array<MatrixRow, EveryRow>] ignored_rows
        def split_rows_into_considered_and_ignored(rows, resolved_ignore_selectors, resolved_selectors = [])
          if resolved_ignore_selectors.any?
            considered, ignored = [], []
            rows.each do | row |
              if ignore_row?(resolved_ignore_selectors, row) || unverified_row_for_ignored_provider_versions?(resolved_selectors, row)
                ignored << row
              else
                considered << row
              end
            end
            return considered, ignored
          else
            return rows, []
          end
        end

        def ignore_row?(resolved_ignore_selectors, row)
          resolved_ignore_selectors.any? do | s |
            s.pacticipant_id == row.consumer_id  && (s.only_pacticipant_name_specified? || s.pacticipant_version_id == row.consumer_version_id) ||
              s.pacticipant_id == row.provider_id  && (s.only_pacticipant_name_specified? || s.pacticipant_version_id == row.provider_version_id)
          end
        end

        # A pact that has never been verified has no provider version, so it can't match an ignore selector
        # that specifies a version (eg. --ignore Bar --version 2). Ignore it when every selected version
        # of the provider has been marked as ignored.
        def unverified_row_for_ignored_provider_versions?(resolved_selectors, row)
          return false unless row.provider_version_id.nil?
          provider_selectors = resolved_selectors.select { | s | s.pacticipant_id == row.provider_id }
          provider_selectors.any? && provider_selectors.all?(&:ignore?)
        end
      end
    end
  end
end
