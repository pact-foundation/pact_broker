require 'spec_helper'
require 'approvals/rspec'

describe Approvals::Namers do

  it "uses the RSpecNamer" do |example|
    approval = Approvals::Approval.new("naming with rspec namer", :namer => Approvals::Namers::RSpecNamer.new(example))
    expect(approval.name).to eq("approvals_namers_uses_the_rspecnamer")
  end

  it "uses the DefaultNamer" do
    approval = Approvals::Approval.new("naming with default namer", :name => "a name")
    expect(approval.name).to eq("a_name")
  end

end
