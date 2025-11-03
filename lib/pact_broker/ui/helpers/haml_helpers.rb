require "haml"

module Haml::Helpers
  using PactBroker::StringRefinements

  def blank?(thing)
    thing.blank?
  end
end

# require "haml"

# module PactBroker
#   module Ui
#     module Helpers
#       module HamlHelpers
#         using PactBroker::StringRefinements

#         def blank?(thing)
#           thing.blank?
#         end
#       end
#     end
#   end
# end
