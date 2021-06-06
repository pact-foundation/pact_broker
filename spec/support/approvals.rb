require "approvals/rspec"
require "pact/support"

Approvals.configure do |c|
  c.approvals_path = "spec/fixtures/approvals/"
end

def print_diff(exception)
  parts = exception.message.split('"')
  received_file = parts[1]
  approved_file = parts[3]
  if File.exist?(received_file) && File.exist?(approved_file)
    received_hash = JSON.parse(File.read(received_file))
    approved_hash = JSON.parse(File.read(approved_file))
    diff = Pact::Matchers.diff(approved_hash, received_hash)
    puts Pact::Matchers::UnixDiffFormatter.call(diff)
  end
end

RSpec.configure do | config |
  config.after(:each) do | example |
    if example.exception.is_a?(Approvals::ApprovalError)
      print_diff(example.exception)
    end
  end
end
