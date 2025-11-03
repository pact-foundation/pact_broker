
module PactBroker
  module Ui
    module Controllers
      class ErrorTest < Base
        include PactBroker::Services

        get "/" do
          raise PactBroker::TestError.new("Don't panic. This is a test UI error.")
        end
      end
    end
  end
end
