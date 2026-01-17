require 'thor'

module Pact
  module MockService
    class CLI < Thor
      ##
      # Custom Thor task allows the following:
      #
      # `script arg1 arg2` to be interpreted as `script <default_task> arg1 arg2`
      # `--option 1 --option 2` to be interpreted as `--option 1 2` (the standard Thor format for multiple value options)
      # `script --help` to display the help for the default task instead of the command list
      #
      class CustomThor < ::Thor
        def self.exit_on_failure? # Thor 1.0 deprecation guard
          false
        end

        no_commands do
          def self.start given_args = ARGV, config = {}
            super(massage_args(given_args))
          end

          def help *args
            if args.empty?
              super(self.class.default_task)
            else
              super
            end
          end

          def self.massage_args argv
            prepend_default_task_name(turn_muliple_tag_options_into_array(argv))
          end

          def self.prepend_default_task_name argv
            if known_first_arguments.include?(argv[0])
              argv
            else
              [default_command] + argv
            end
          end

          # other task names, help, and the help shortcuts
          def self.known_first_arguments
            @known_first_arguments ||= tasks.keys + ::Thor::HELP_MAPPINGS + ['help']
          end

          def self.turn_muliple_tag_options_into_array argv
            new_argv = []
            opt_name = nil
            argv.each_with_index do | arg, i |
              if arg.start_with?('-')
                opt_name = arg
                existing = new_argv.find { | a | a.first == opt_name }
                if !existing
                  new_argv << [arg]
                end
              else
                if opt_name
                  existing = new_argv.find { | a | a.first == opt_name }
                  existing << arg
                  opt_name = nil
                else
                  new_argv << [arg]
                end
              end
            end
            new_argv.flatten
          end
        end
      end
    end
  end
end