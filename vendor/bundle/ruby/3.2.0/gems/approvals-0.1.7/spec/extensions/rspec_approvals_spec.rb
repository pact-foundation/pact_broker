require 'approvals/rspec'

shared_context 'verify examples' do
  specify "a string" do
    verify do
      "We have, I fear, confused power with greatness."
    end
  end

  specify "an array" do
    verify do
      array = [
        "abc",
        123,
        :zomg_fooooood,
        %w(cheese burger ribs steak bacon)
      ]
    end
  end

  specify "a complex object" do
    verify do
      hello = Object.new
      def hello.to_s
        "Hello, World!"
      end

      def hello.inspect
        "#<The World Says: Hello!>"
      end

      hello
    end
  end

  specify "html" do
    verify :format => :html do
      html = <<-HTML
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "DTD/xhtml1-strict.dtd"><html><head><title>Approval</title></head><body><h1>An Approval</h1><p>It has a paragraph</p></body></html>
      HTML
    end
  end

  specify "xml" do
    verify :format => :xml do
      xml = "<xml char=\"kiddo\"><node><content name='beatrice' /></node><node aliases='5'><content /></node></xml>"
    end
  end

  specify "json" do
    verify :format => :json do
      json = '{"pet":{"species":"turtle","color":"green","name":"Anthony"}}'
    end
  end

  specify "an executable" do
    verify do
      executable('SELECT 1') do |command|
        puts "your slip is showing (#{command})"
      end
    end
  end

  specify "a failure" do
    expect { verify { 'no.' } }.to raise_error(Approvals::ApprovalError)
  end

  specify "a failure diff" do
    ::RSpec.configuration.diff_on_approval_failure = true
    expect(::RSpec::Expectations).to receive(:fail_with)
    verify { 'no.' }
    ::RSpec.configuration.diff_on_approval_failure = false
  end

  specify "a failure diff", :diff_on_approval_failure => true do
    expect(::RSpec::Expectations).to receive(:fail_with)
    verify { 'no.' }
  end
end

RSpec.configure do |c|
  c.after :each do
    c.approvals_namer_class = nil
  end
end

describe "Verifies" do
  before :each do
    RSpec.configure do |c|
      c.approvals_namer_class = Approvals::Namers::RSpecNamer
    end
  end

  include_context 'verify examples'
end

describe "Verifies (directory)" do
  before :each do
    RSpec.configure do |c|
      c.approvals_namer_class = Approvals::Namers::DirectoryNamer
    end
  end

  include_context 'verify examples'
end
