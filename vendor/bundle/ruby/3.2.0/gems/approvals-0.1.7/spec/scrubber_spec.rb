require 'spec_helper'
require 'approvals/scrubber'

describe Approvals::Scrubber do

  describe "defaults" do
    let(:path) { File.expand_path('.') }
    subject { Approvals::Scrubber.new("I am currently at #{path}") }

    it "has a sensible to_s" do
      expect(subject.to_s).to eq("I am currently at {{current_dir}}")
    end

    it "unscrubs" do
      expect(subject.unscrub).to eq("I am currently at #{path}")
    end

    it "unscrubs any old string" do
      expect(subject.unscrub("Hoy, where's {{current_dir}}?")).to eq("Hoy, where's #{path}?")
    end
  end

  it "overrides default hash" do
    expect(Approvals::Scrubber.new("oh, my GAWD", {"deity" => "GAWD"}).to_s).to eq('oh, my {{deity}}')
  end
end
