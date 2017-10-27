require 'pact_broker/api/resources/matrix'
require 'pact_broker/matrix/service'

module PactBroker
  module Api
    module Resources
      describe Matrix do
        before do
          allow(PactBroker::Matrix::Service).to receive(:validate_selectors).and_return(error_messages)
        end

        let(:td) { TestDataBuilder.new }
        let(:path) { "/matrix" }
        let(:json_response_body) { JSON.parse(subject.body, symbolize_names: true) }
        let(:params) { {q: [{pacticipant: 'Foo', version: '1'}, {pacticipant: 'Bar', version: '2'}]} }
        let(:error_messages) { [] }

        subject { get path, params, {'Content-Type' => 'application/hal+json'}; last_response }

        it "validates the selectors" do
          expect(PactBroker::Matrix::Service).to receive(:validate_selectors).with('Foo' => '1', 'Bar' => '2')
          subject
        end

        context "when a validation error occurs" do
          let(:error_messages) { ['foo'] }
          it "returns a 400 status" do
            expect(subject.status).to eq 400
          end

          it "returns error messages" do
            expect(json_response_body[:errors]).to eq ['foo']
          end
        end
      end
    end
  end
end
