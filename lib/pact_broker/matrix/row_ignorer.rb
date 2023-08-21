module PactBroker
  module Matrix
    class RowIgnorer

      class << self
        # Splits the matrix rows into considered rows and ignored rows, based on the
        # ignore selectors specified by the user in the can-i-deploy command (eg. --ignore SomeProviderThatIsNotReadyYet).
        # @param [Array<QuickRow, EveryRow>] rows
        # @param [<PactBroker::Matrix::ResolvedSelector>] resolved_ignore_selectors
        # @return [Array<QuickRow, EveryRow>] considered_rows, [Array<QuickRow, EveryRow>] ignored_rows
        def split_rows_into_considered_and_ignored(rows, resolved_ignore_selectors)
          if resolved_ignore_selectors.any?
            considered, ignored = [], []
            rows.each do | row |
              if ignore_row?(resolved_ignore_selectors, row)
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
      end
    end
  end
end
