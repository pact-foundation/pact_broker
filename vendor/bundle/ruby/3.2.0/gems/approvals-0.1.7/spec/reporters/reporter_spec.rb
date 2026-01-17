require 'spec_helper'
require 'approvals/reporters'

describe Approvals::Reporters::Reporter do

  it "is not approved by default" do
    expect(Approvals::Reporters::Reporter.new).not_to be_approved_when_reported
  end

  it "takes a launcher" do
    move = lambda {|received, approved|
      "echo \"mv #{received} #{approved}\""
    }

    expect(Approvals::Reporters::Reporter.new(&move).launcher.call('received.txt', 'approved.txt')).to eq("echo \"mv received.txt approved.txt\"")
  end

  it "defaults to the default OpenDiff launcher" do
    expect(Approvals::Reporters::Reporter.new.launcher).to eq(Approvals::Reporters::Launcher.opendiff)
  end
end
