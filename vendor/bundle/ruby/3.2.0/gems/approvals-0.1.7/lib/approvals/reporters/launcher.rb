
module Approvals
  module Reporters
    module Launcher

      class << self
        REPORTERS = [:opendiff, :diffmerge, :vimdiff, :tortoisediff, :filelauncher]

        def memoized(instance_variable)
          unless self.instance_variable_get(instance_variable)
            value = yield
            self.instance_variable_set(instance_variable, value)
          end
          self.instance_variable_get(instance_variable)
        end

        REPORTERS.each do |name|
          define_method name do
            memoized(:"@#{name}") do
              lambda {|received, approved|
                self.send("#{name}_command".to_sym, received, approved)
              }
            end
          end
        end

        def opendiff_command(received, approved)
          "opendiff #{received} #{approved}"
        end

        def diffmerge_command(received, approved)
          "/Applications/DiffMerge.app/Contents/MacOS/DiffMerge --nosplash \"#{received}\" \"#{approved}\""
        end

        def vimdiff_command(received, approved)
          "vimdiff #{received} #{approved}"
        end

        def tortoisediff_command(received, approved)
          "C:\\Program Files\\TortoiseSVN\\bin\\TortoiseMerge.exe #{received} #{approved}"
        end

        def filelauncher_command(received, approved)
          "open #{received}"
        end
      end
    end
  end
end
