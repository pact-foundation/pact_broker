require 'pact_broker/config/load'

module PactBroker
  module Config
    describe Load do

      describe ".call" do

        class MockConfig
          attr_accessor :foo, :bar, :nana, :meep, :lalala, :meow, :peebo
        end

        before do
          Setting.create(name: 'foo', type: 'json', value: {"a" => "thing"}.to_json)
          Setting.create(name: 'bar', type: 'string', value: "bar")
          Setting.create(name: 'nana', type: 'integer', value: "1")
          Setting.create(name: 'meep', type: 'float', value: "1.2")
          Setting.create(name: 'lalala', type: 'boolean', value: "1")
          Setting.create(name: 'meow', type: 'boolean', value: "0")
          Setting.create(name: 'peebo', type: 'string', value: nil)
          Setting.create(name: 'unknown', type: 'string', value: nil)
        end

        let(:configuration) { MockConfig.new }

        subject { Load.call(configuration) }

        it "loads a JSON config" do
          subject
          expect(configuration.foo).to eq(a: "thing")
        end

        it "loads a String setting" do
          subject
          expect(configuration.bar).to eq "bar"
        end

        it "loads an Integer setting" do
          subject
          expect(configuration.nana).to eq 1
        end

        it "loads a Float setting" do
          subject
          expect(configuration.meep).to eq 1.2
        end

        it "loads a true setting" do
          subject
          expect(configuration.lalala).to eq true
        end

        it "loads a false setting" do
          subject
          expect(configuration.meow).to eq false
        end

        it "loads a nil setting" do
          subject
          expect(configuration.peebo).to eq nil
        end

        it "does not load a setting where the Configuration object does not have a matching property" do
          allow(Load.logger).to receive(:warn)
          expect(Load.logger).to receive(:warn).with("Could not load configuration setting \"unknown\" as there is no matching attribute on the Configuration class")
          subject
        end
      end
    end
  end
end
