require 'spec_helper'

describe ConventionalChangelog::Git do
  subject { ConventionalChangelog::Git }

  describe ".log" do
    it "returns a log with default options" do
      log = subject.log({})

      expect(log).to include "feat(bin): add a conventional-changelog binary"
    end

    it "raises an exception if Git returns an error" do
      expect do
        subject.log({ since_version: 'invalid-branch' })
      end.to raise_exception RuntimeError, "Can't load Git commits, check your arguments"
    end
  end
end
