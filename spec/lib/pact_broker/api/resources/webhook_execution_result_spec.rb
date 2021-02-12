module PactBroker
  module Webhooks
    describe WebhookExecutionResult do
      subject { WebhookExecutionResult::new(request, response, nil) }
      let(:request) do
        Net::HTTP::Get.new("http://example.org?foo=bar")
      end

      context "When 'webhook_http_code_success' has: [200, 201]" do
        before do
          allow(PactBroker.configuration).to receive(:webhook_http_code_success).and_return([200, 201])
        end

        context "and response is '200'" do
          let(:response) { double(code: '200') }

          it "then it should be success" do
            expect(subject.success?).to be_truthy
          end
        end

        context "and response is '400'" do
          let(:response) { double(code: '400') }

          it "then it should fail" do
            expect(subject.success?).to be_falsey
          end
        end
      end


      context "When 'webhook_http_code_success' has: [400, 401]" do
        before do
          allow(PactBroker.configuration).to receive(:webhook_http_code_success).and_return([400, 401])
        end

        context "and response is '200'" do
          let(:response) { double(code: '200') }

          it "then it should fail" do
            expect(subject.success?).to be_falsey
          end
        end

        context "and response is '400'" do
          let(:response) { double(code: '400') }

          it "then it should be success" do
            expect(subject.success?).to be_truthy
          end
        end
      end

    end
  end
end
