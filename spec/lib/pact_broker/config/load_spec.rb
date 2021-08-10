require "pact_broker/config/load"

module PactBroker
  module Config
    describe Load do
      describe ".call" do

        class MockConfig < Anyway::Config
          attr_config(
            foo: "default",
            bar: "default",
            nana: "default",
            meep: "default",
            lalala: "default",
            meow: "default",
            peebo: "default",
            whitelist: "default",
            blah: "default",
            setting_with_override: "default"
          )
          attr_config(:setting_with_no_default)
          config_name :foo
        end

        before do
          Setting.create(name: "foo", type: "json", value: {"a" => "thing"}.to_json)
          Setting.create(name: "bar", type: "string", value: "bar")
          Setting.create(name: "nana", type: "integer", value: "1")
          Setting.create(name: "meep", type: "float", value: "1.2")
          Setting.create(name: "lalala", type: "boolean", value: "1")
          Setting.create(name: "meow", type: "boolean", value: "0")
          Setting.create(name: "peebo", type: "string", value: nil)
          Setting.create(name: "unknown", type: "string", value: nil)
          Setting.create(name: "whitelist", type: "space_delimited_string_list", value: "foo bar")
          Setting.create(name: "blah", type: "symbol", value: "boop")
          Setting.create(name: "setting_with_no_default", type: "string", value: "boop")
          Setting.create(name: "setting_with_override", type: "string", value: "meep")

          allow(Load.logger).to receive(:warn)
          allow(Load.logger).to receive(:debug)
        end

        let(:configuration) { MockConfig.new(setting_with_override: "overridden") }

        subject { Load.call(configuration) }

        it "loads a JSON config" do
          subject
          expect(configuration.foo).to eq(a: "thing")
        end

        it "loads a String setting" do
          subject
          expect(configuration.bar).to eq "bar"
        end

        it "loads a Symbol setting" do
          subject
          expect(configuration.blah).to eq :boop
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

        it "loads a space_delimited_string_list" do
          subject
          expect(configuration.whitelist).to eq ["foo", "bar"]
        end

        it "loads settings where there is no default" do
          subject
          expect(configuration.setting_with_no_default).to eq "boop"
        end

        it "does not overwrite settings that did not come from the default class" do
          expect(Load.logger).to receive(:debug).with(/Ignoring.*setting_with_override/)
          subject
          expect(configuration.setting_with_override).to eq "overridden"
        end

        it "does not load a setting where the Configuration object does not have a matching property" do
          expect(Load.logger).to receive(:warn).with("Could not load configuration setting \"unknown\" as there is no matching attribute on the PactBroker::Config::MockConfig class")
          subject
        end
      end
    end
  end
end
