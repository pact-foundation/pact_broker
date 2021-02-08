module PactBroker
  module Versions
    module LazyLoaders
      LATEST_VERSION_FOR_BRANCH = lambda {
        self.class
          .where(branch: branch, pacticipant_id: pacticipant_id)
          .exclude(branch: nil)
          .order(Sequel.desc(:order))
          .limit(1)
      }
    end
  end
end
