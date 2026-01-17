module Approvals
  module DSL
    def verify(object, options = {})
      Approval.new(object, options).verify
    end
  end
end
