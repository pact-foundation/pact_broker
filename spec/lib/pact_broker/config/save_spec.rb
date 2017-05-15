require 'pact_broker/config/save'
require 'pact_broker/configuration'

module PactBroker
  module Config
    describe Save do

      describe "SETTING_NAMES" do
        let(:configuration) { PactBroker::Configuration.new}

        Save::SETTING_NAMES.each do | setting_name |
          describe setting_name do
            it "exists as a method on a PactBroker::Configuration instance" do
              expect(configuration).to respond_to(setting_name)
            end
          end
        end

      end

      describe "#call" do
        before do
          stub_const("PactBroker::Config::Save::SETTING_NAMES", [:foo, :bar, :wiffle, :meep, :flop, :peebo, :lalala, :meow])
        end
        let(:configuration) do
          double("PactBroker::Configuration",
            foo: true,
            bar: false,
            wiffle: ["a", "b", "c"],
            meep: {a: 'thing'},
            flop: nil,
            peebo: 1,
            lalala: 1.2,
            meow: Object.new)
        end

        subject { Save.call(configuration) }

        it "saves a false config setting to the database" do
          subject
          setting = Setting.find(name: 'foo')
          expect(setting.type).to eq 'Boolean'
          expect(setting.value).to eq '1'
        end

        it "saves a true config setting to the database" do
          subject
          setting = Setting.find(name: 'bar')
          expect(setting.type).to eq 'Boolean'
          expect(setting.value).to eq '0'
        end

        it "saves an array to the database" do
          subject
          setting = Setting.find(name: 'wiffle')
          expect(setting.type).to eq 'JSON'
          expect(setting.value).to eq '["a","b","c"]'
        end

        it "saves a hash to the database" do
          subject
          setting = Setting.find(name: 'meep')
          expect(setting.type).to eq 'JSON'
          expect(setting.value).to eq "{\"a\":\"thing\"}"
        end

        it "saves a nil to the database" do
          subject
          setting = Setting.find(name: 'flop')
          expect(setting.type).to eq 'String'
          expect(setting.value).to eq nil
        end

        it "saves an Integer to the database" do
          subject
          setting = Setting.find(name: 'peebo')
          expect(setting.type).to eq 'Integer'
          expect(setting.value).to eq '1'
        end

        it "saves a Float to the database" do
          subject
          setting = Setting.find(name: 'lalala')
          expect(setting.type).to eq 'Float'
          expect(setting.value).to eq '1.2'
        end

        it "does not save an arbitrary object to the database" do
          allow(Save.logger).to receive(:warn)
          expect(Save.logger).to receive(:warn).with("Could not save configuration setting \"meow\" to database as the class Object is not supported.")
          subject
          setting = Setting.find(name: 'meow')
          expect(setting).to be nil
        end
      end
    end
  end
end
