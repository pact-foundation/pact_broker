require 'sucker_punch'
require 'pact_broker/matrix/head_row'

module PactBroker
  module Matrix
    class RefreshHeadMatrixJob

      include SuckerPunch::Job
      include PactBroker::Logging

      def perform params
        PactBroker::Matrix::HeadRow.refresh(params[:params])
      end
    end
  end
end
