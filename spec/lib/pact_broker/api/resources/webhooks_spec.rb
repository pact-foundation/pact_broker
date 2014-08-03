require 'pact_broker/api/resources/webhooks'

module PactBroker::Api

  module Resources

    describe Webhooks do

      describe "POST" do
        let(:webhook_json) do
          {
            method: 'POST',
            url: 'http://blah.com',
            headers: {''}
          }
        end

        let(:uuid) { '1483234k24DKFGJ45K' }

        before do
          allow(SecureRandom).to receive(:urlsafe_base64).and_return(uuid)
        end
        it "creates a webhook" do
          post "/webhooks/provider/Some%20Provider/consumer/Some%20Consumer", webhook_json, {'CONTENT_TYPE' => 'application/json'}
        end
      end



    end
  end

end
