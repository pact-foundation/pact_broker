require 'spec_helper'

describe Approvals::Reporters::OpendiffReporter do

  it "has a nice launcher" do
    skip "Breaks off execution of the tests. Horrible."
    one = 'spec/fixtures/one.txt'
    two = 'spec/fixtures/two.txt'
    executable = Approvals::Executable.new(Approvals::Reporters::OpendiffReporter.instance.launcher.call(one, two)) do |command|
      Approvals::Reporters::OpendiffReporter.report(one, two)
    end

    Approvals.verify(executable, :name => 'opendiff launcher')
  end
end
