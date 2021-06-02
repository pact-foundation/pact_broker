require "pact_broker/config/load"
require "pact_broker/config/save"

module PactBroker
  module Config
    describe "Save and Load" do

      let(:setting_names) { configuration_to_save.to_h.keys }
      let(:configuration_to_save) do
        OpenStruct.new(foo: true, bar: false, wiffle: nil, meep: [1, "2"], mop: {a: "b"}, la: 1, lala: 1.2)
      end

      let(:loaded_configuration) do
        OpenStruct.new(foo: nil, bar: "1", wiffle: [], meep: nil, mop: nil, la: nil, lala: nil)
      end

      subject { Save.call(configuration_to_save, setting_names); Load.call(loaded_configuration) }

      it "the loaded configuration is the same as the saved one" do
        subject
        expect(loaded_configuration).to eq configuration_to_save
      end
    end
  end
end
