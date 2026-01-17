require 'spec_helper'
require 'approvals/system_command'

describe Approvals::SystemCommand, "#exists?" do

  it "does" do
    expect(Approvals::SystemCommand.exists?("ls")).to be_truthy
  end

  it "does not" do
    expect(Approvals::SystemCommand.exists?("absolutelydoesnotexistonyoursystem")).to be_falsey
  end
end
