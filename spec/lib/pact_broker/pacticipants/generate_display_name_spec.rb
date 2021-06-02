require "pact_broker/pacticipants/generate_display_name"

module PactBroker
  module Pacticipants
    describe GenerateDisplayName do
      describe ".call" do
        TEST_CASES = {
          "foo" => "Foo",
          "MyService" => "My Service",
          "my-service" => "My Service",
          "my_service" => "My Service",
          "my service" => "My Service",
          "ABCService" => "ABC Service",
          "A4Service" => "A4 Service",
          "SNSPactEventConsumer" => "SNS Pact Event Consumer",
          "AWSSummiteerWeb" => "AWS Summiteer Web",
          "Beer-Consumer" => "Beer Consumer",
          "foo.pretend-consumer" => "Foo Pretend Consumer",
          "Client-XX" => "Client XX",
          "providerJSWorkshop" => "Provider JS Workshop",
          "e2e Provider Example" => "E2e Provider Example",
          "MP - Our Provider" => "MP - Our Provider",
          "PoC - Pact-broker-consumer" => "PoC - Pact Broker Consumer",
          "QB-DATABASE Service" => "QB DATABASE Service",
          "Support Species App (Provider)" => "Support Species App (Provider)",
          9 => "9",
          "" => "",
          nil => nil
        }

        TEST_CASES.each do | name, expected_display_name |
          it "converts #{name.inspect} to #{expected_display_name.inspect}" do
            expect(GenerateDisplayName.call(name)).to eq expected_display_name
          end
        end
      end
    end
  end
end
