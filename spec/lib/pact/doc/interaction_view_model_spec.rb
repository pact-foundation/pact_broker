require 'pact/doc/interaction_view_model'

module Pact
  module Doc
    describe InteractionViewModel do
      let(:consumer_contract) { Pact::ConsumerContract.from_uri './spec/support/interaction_view_model.json' }
      let(:interaction_with_request_with_body_and_headers) { consumer_contract.find_interaction description: "a request with a body and headers" }
      let(:interaction_with_request_without_body_and_headers) { consumer_contract.find_interaction description: "a request with an empty body and empty headers" }
      let(:interaction_with_response_with_body_and_headers) { consumer_contract.find_interaction description: "a response with a body and headers" }
      let(:interaction_with_response_without_body_and_headers) { consumer_contract.find_interaction description: "a response with an empty body and empty headers" }
      let(:interaction) { consumer_contract.interactions.first }

      subject { InteractionViewModel.new interaction, consumer_contract}

      describe "id" do
        context "with HTML characters in the description" do
          before do
            interaction.description = "an alligator with > 100 legs exists"
            interaction.provider_state = "a thing exists"
          end

          it "escapes the HTML characters" do
            expect(subject.id).to eq "an_alligator_with_&gt;_100_legs_exists_given_a_thing_exists"
          end
        end
      end

      describe "consumer_name" do
        context "with markdown characters in the name" do
          it "escapes the markdown characters" do
            expect(subject.consumer_name).to eq "a\\*consumer"
          end
        end
      end

      describe "provider_name" do
        context "with markdown characters in the name" do
          it "escapes the markdown characters" do
            expect(subject.provider_name).to eq "a\\_provider"
          end
        end
      end

      describe "request" do
        let(:interaction) { interaction_with_request_with_body_and_headers }

        it "includes the method" do
          expect(subject.request).to include('"method"')
          expect(subject.request).to include('"get"')
        end

        it "includes the body" do
          expect(subject.request).to include('"body"')
          expect(subject.request).to include('"a body"')
        end

        it "includes the headers" do
          expect(subject.request).to include('"headers"')
          expect(subject.request).to include('"a header"')
        end

        it "includes the query" do
          expect(subject.request).to include('"query"')
          expect(subject.request).to include('"some=thing"')
        end

        it "includes the path" do
          expect(subject.request).to include('"path"')
          expect(subject.request).to include('"/path"')
        end

        it "renders the keys in a meaningful order" do
          expect(subject.request).to match(/"method".*"path".*"query".*"headers".*"body"/m)
        end

        context "when the body hash is empty" do
          let(:interaction) { interaction_with_request_without_body_and_headers }

          it "includes the body" do
            expect(subject.request).to include("body")
          end
        end
        context "when the headers hash is empty" do
          let(:interaction) { interaction_with_request_without_body_and_headers }

          it "does not include the headers" do
            expect(subject.request).to_not include("headers")
          end
        end

        context "when a Pact::Term is present" do
          let(:consumer_contract) { Pact::ConsumerContract.from_uri './spec/support/interaction_view_model_with_terms.json'}
          let(:interaction) { consumer_contract.interactions.first }

          it "uses the generated value" do
            expect(subject.request).to_not include("Term")
            expect(subject.request).to include("sunny")
          end
        end
      end

      describe "response" do
        let(:interaction) { interaction_with_response_with_body_and_headers }

        it "includes the status" do
          expect(subject.response).to include('"status"')
        end

        it "includes the body" do
          expect(subject.response).to include('"body"')
          expect(subject.response).to include('"a body"')
        end
        it "includes the headers" do
          expect(subject.response).to include('"headers"')
          expect(subject.response).to include('"a header"')
        end

        it "renders the keys in a meaningful order" do
          expect(subject.response).to match(/"status".*"headers".*"body"/m)
        end

        context "when the body hash is empty" do
          let(:interaction) { interaction_with_response_without_body_and_headers }

          it "does not include the body" do
            expect(subject.response).to_not include("body")
          end
        end

        context "when the headers hash is empty" do
          let(:interaction) { interaction_with_response_without_body_and_headers }

          it "does not include the headers" do
            expect(subject.response).to_not include("headers")
          end
        end

        context "when a Pact::Term is present" do
          let(:consumer_contract) { Pact::ConsumerContract.from_uri './spec/support/interaction_view_model_with_terms.json'}
          let(:interaction) { consumer_contract.interactions.first }

          it "uses the generated value" do
            expect(subject.response).to_not include("Term")
            expect(subject.response).to include("rainy")
          end
        end
      end

      describe "description" do
        context "with a nil description" do
          let(:interaction) do
            interaction_with_request_with_body_and_headers.description = nil
            interaction_with_request_with_body_and_headers
          end

          it "does not blow up" do
            expect(subject.description(true)).to eq ''
            expect(subject.description(false)).to eq ''
          end
        end

        context "with markdown characters in the name" do
          let(:interaction) do
            interaction_with_request_with_body_and_headers.description = 'a *description'
            interaction_with_request_with_body_and_headers
          end
          it "escapes the markdown characters" do
            expect(subject.description).to eq "a \\*description"
          end
        end
      end

      describe "provider_state" do
        context "with markdown characters in the name" do
          let(:interaction) do
            interaction_with_request_with_body_and_headers.provider_state = 'a *provider state'
            interaction_with_request_with_body_and_headers
          end
          it "escapes the markdown characters" do
            expect(subject.provider_state).to eq "a \\*provider state"
          end
        end
      end

      describe "formatted_provider_states" do
        let(:consumer_contract) { Pact::ConsumerContract.from_uri './spec/support/markdown_pact.json' }
        let(:interaction) { consumer_contract.interactions.first }

        context "when no provider state" do
          let(:interaction) { consumer_contract.interactions.last }

          it "returns an empty string" do
            expect(subject.formatted_provider_states).to eq ""
          end
        end

        context "when marking provider states in bold" do
          it "formats the provider state in bold" do
            expect(subject.formatted_provider_states mark_bold: true).to eq "**alligators exist**"
          end
        end
        
        context "when not marking provider states in bold" do
          it "formats the provider state without bold" do
            expect(subject.formatted_provider_states).to eq "alligators exist"
          end
        end

        context "when using v3 specification" do
          let(:consumer_contract) { Pact::ConsumerContract.from_uri './spec/support/markdown_pact_v3.json' }
          let(:interaction) { consumer_contract.interactions.first }

          context "when marking provider states in bold" do
            it "formats the provider states in bold" do
              expected_result = '**alligators exist** and **the city of Tel Aviv has a zoo** ' \
                                'and **the zoo keeps record of its alligator population**'
              expect(subject.formatted_provider_states mark_bold: true).to eq expected_result
            end
          end

          context "when not marking provider states in bold" do
            it "formats the provider states without bold" do
              expected_result = 'alligators exist and the city of Tel Aviv has a zoo ' \
                                'and the zoo keeps record of its alligator population'
              expect(subject.formatted_provider_states).to eq expected_result
            end
          end
        end
      end
    end
  end
end
