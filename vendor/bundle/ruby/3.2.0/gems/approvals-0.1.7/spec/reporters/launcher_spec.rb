require 'spec_helper'
require 'approvals/reporters/launcher'

describe Approvals::Reporters::Launcher do
  it "has a vimdiff launcher" do
    expect(described_class.vimdiff.call('one', 'two')).to eq("vimdiff one two")
  end

  it "has an opendiff launcher" do
    expect(described_class.opendiff.call('one', 'two')).to eq("opendiff one two")
  end

  it "has a diffmerge launcher" do
    expect(described_class.diffmerge.call('one', 'two')).to match(/DiffMerge.*\"one\"\ \"two\"/)
  end

  it "has a tortoisediff launcher" do
    expect(described_class.tortoisediff.call('one', 'two')).to match(/TortoiseMerge.exe.*one.*two/)
  end

  it "has a filelauncher launcher" do
    expect(described_class.filelauncher.call('one', 'two')).to eq("open one")
  end
end
