require 'spec_helper'
require 'approvals/reporters/first_working_reporter'

describe Approvals::Reporters::FirstWorkingReporter do


  let(:no) { double(:working_in_this_environment? => false) }
  let(:yes) { double(:working_in_this_environment? => true) }
  let(:yes_too) { double(:working_in_this_environment? => true) }

  it "when at least one reporter works it is working" do
    reporter = Approvals::Reporters::FirstWorkingReporter.new(no, yes)
    expect(reporter).to be_working_in_this_environment
  end

  it "when no reporters work it's not working" do
    reporter = Approvals::Reporters::FirstWorkingReporter.new(no, no)
    expect(reporter).not_to be_working_in_this_environment
  end

  it "calls the first working reporter" do
    working = Approvals::Reporters::FirstWorkingReporter.new(no, yes, yes_too)

    expect(no).not_to receive(:report)
    expect(yes).to receive(:report)
    expect(yes_too).not_to receive(:report)

    working.report("r", "a")
  end
end
