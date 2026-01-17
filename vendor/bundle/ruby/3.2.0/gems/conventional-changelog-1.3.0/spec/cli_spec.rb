require 'spec_helper'
require 'conventional_changelog/cli'

describe ConventionalChangelog::CLI do
  describe ".execute" do
    it 'runs clean' do
      expect { ConventionalChangelog::CLI.execute [] }.to_not raise_exception  
    end

    context "with empty arguments" do
      it 'generates a changelog' do
        expect_any_instance_of(ConventionalChangelog::Generator).to receive(:generate!).with({})
        ConventionalChangelog::CLI.execute []
      end
    end

    context "with version=x.y.z" do
      it 'generates a changelog with the version' do
        expect_any_instance_of(ConventionalChangelog::Generator).to receive(:generate!).with version: "x.y.z"
        ConventionalChangelog::CLI.execute ["version=x.y.z"]
      end
    end
  end
end
