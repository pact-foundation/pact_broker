require "roar/decorator"
require "roar/json/hal"

module PactBroker
  module Api
    module Decorators
      module PaginationLinks
        include Roar::JSON::HAL
        include Roar::JSON::HAL::Links

        link :next do | context |
          if represented.respond_to?(:current_page) &&
              represented.respond_to?(:page_count) &&
              represented.current_page < represented.page_count
            {
              href: context[:resource_url] + "?pageSize=#{represented.page_size}&pageNumber=#{represented.current_page + 1}",
              title: "Next page"
            }

          end
        end

        link :previous do | context |
          if represented.respond_to?(:first_page?) && !represented.first_page?
            {
              href: context[:resource_url] + "?pageSize=#{represented.page_size}&pageNumber=#{represented.current_page - 1}",
              title: "Previous page"
            }
          end
        end
      end
    end
  end
end
