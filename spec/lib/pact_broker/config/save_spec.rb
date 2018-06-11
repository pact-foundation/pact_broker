require 'pact_broker/config/save'
require 'pact_broker/configuration'
require 'pact_broker/config/space_delimited_string_list'

module PactBroker
  module Config
    describe Save do

      describe "#call" do
        let(:setting_names) { [:foo, :bar, :wiffle, :meep, :flop, :peebo, :lalala, :meow, :whitelist] }
        let(:configuration) do
          double("PactBroker::Configuration",
            foo: true,
            bar: false,
            wiffle: ["a", "b", "c"],
            meep: {a: 'thing'},
            flop: nil,
            peebo: 1,
            lalala: 1.2,
            meow: Object.new,
            whitelist: SpaceDelimitedStringList.parse("foo bar"))
        end

        subject { Save.call(configuration, setting_names) }

        it "saves a false config setting to the database" do
          subject
          setting = Setting.find(name: 'foo')
          expect(setting.type).to eq 'boolean'
          expect(setting.value).to eq '1'
        end

        it "saves a true config setting to the database" do
          subject
          setting = Setting.find(name: 'bar')
          expect(setting.type).to eq 'boolean'
          expect(setting.value).to eq '0'
        end

        it "saves an array to the database" do
          subject
          setting = Setting.find(name: 'wiffle')
          expect(setting.type).to eq 'json'
          expect(setting.value).to eq '["a","b","c"]'
        end

        it "saves a hash to the database" do
          subject
          setting = Setting.find(name: 'meep')
          expect(setting.type).to eq 'json'
          expect(setting.value).to eq "{\"a\":\"thing\"}"
        end

        it "saves a nil to the database" do
          subject
          setting = Setting.find(name: 'flop')
          expect(setting.type).to eq 'string'
          expect(setting.value).to eq nil
        end

        it "saves an Integer to the database" do
          subject
          setting = Setting.find(name: 'peebo')
          expect(setting.type).to eq 'integer'
          expect(setting.value).to eq '1'
        end

        it "saves a Float to the database" do
          subject
          setting = Setting.find(name: 'lalala')
          expect(setting.type).to eq 'float'
          expect(setting.value).to eq '1.2'
        end

        it "saves a SpaceDelimitedStringList" do
          subject
          setting = Setting.find(name: 'whitelist')
          expect(setting.type).to eq 'space_delimited_string_list'
          expect(setting.value).to eq 'foo bar'
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
