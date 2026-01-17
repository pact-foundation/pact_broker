module Approvals
  module Namers
    class DirectoryNamer < RSpecNamer
      private

      def name_for_example(example)
        directorize example
      end

      def directorize(example)
        approvals_path = lambda do |metadata|
          description = normalize metadata[:description]
          example_group = if metadata.key?(:example_group)
                            metadata[:example_group]
                          else
                            metadata[:parent_example_group]
                          end

          if example_group
            [approvals_path[example_group], description].join('/')
          else
            description
          end
        end

        approvals_path[example.metadata]
      end
    end
  end
end
