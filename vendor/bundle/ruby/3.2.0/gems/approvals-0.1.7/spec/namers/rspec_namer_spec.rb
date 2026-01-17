require 'spec_helper'

describe Approvals::Namers::RSpecNamer do

  it "uses non-$%^&*funky example description" do |example|
    expect(Approvals::Namers::RSpecNamer.new(example).name).to eq 'approvals_namers_rspecnamer_uses_non_funky_example_description'
  end

  it "has a decent default" do |example|
    expect(Approvals::Namers::RSpecNamer.new(example).output_dir).to eq 'spec/fixtures/approvals/'
  end

  context "when RSpec is configured" do
    before :each do
      RSpec.configure do |c|
        c.approvals_path = 'spec/output/dir/'
      end
    end

    after :each do
      RSpec.configure do |c|
        c.approvals_path = nil
      end
    end

    it "uses the rspec config option" do |example|
      expect(Approvals::Namers::RSpecNamer.new(example).output_dir).to eq 'spec/output/dir/'
    end
  end
end
