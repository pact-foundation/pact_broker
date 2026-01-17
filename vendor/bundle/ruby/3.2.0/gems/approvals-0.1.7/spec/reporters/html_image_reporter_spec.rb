require 'spec_helper'
require 'approvals/reporters'
require 'approvals/scrubber'

describe Approvals::Reporters::HtmlImageReporter do

  subject { Approvals::Reporters::HtmlImageReporter.instance }

  it "creates the template" do
    scrubber = Approvals::Scrubber.new(subject.html("spec/fixtures/one.png", "spec/fixtures/two.png"))
    expect(scrubber.to_s).to eq('<html><head><title>Approval</title></head><body><center><table style="text-align: center;" border="1"><tr><td><img src="file://{{current_dir}}/spec/fixtures/one.png"></td><td><img src="file://{{current_dir}}/spec/fixtures/two.png"></td></tr><tr><td>received</td><td>approved</td></tr></table></center></body></html>')
  end

  # verify "creates the appropriate command", :format => :html do
  #   reporter = Reporters::HtmlImageReporter.instance
  #   scrubber = Scrubber.new(reporter.html("spec/fixtures/one.png", "spec/fixtures/two.png"))
  #   scrubber.to_executable do |html|
  #     reporter.display(html)
  #   end
  # end

end
