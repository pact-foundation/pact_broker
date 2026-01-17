require 'spec_helper'
require 'approvals/namers/rspec_namer'

describe Approvals do

  def some_function(a1,b1,c1)
    "#{b1+c1} #{a1}s"
  end

  let(:namer) { |example| Approvals::Namers::RSpecNamer.new(example) }

  specify "2 combos" do
    a = ["foo", "bar"]
    b = [1,3,5]
    c = [2,4]
    CombinationApprovals.verify_all_combinations(a,b, c, namer:namer) do |a1,b1, c1|
      "#{b1+c1} #{a1}s"
    end
    CombinationApprovals.verify_all_combinations(a,b, c,namer:namer, &method(:some_function))
  end

  specify "errors" do
    a = ["foo", "bar"]
    b = [0,1,2]
    CombinationApprovals.verify_all_combinations(a,b, namer:namer) do |a1,b1|
      if b1 == 2
        raise "There is no 2"
      end
      "#{b1} #{a1}s"
    end
  end
end
