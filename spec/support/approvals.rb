require "approvals/rspec"
require "pact/support"
require "yaml"

class YamlFormat < Approvals::Writers::TextWriter
  def format(data)
    data.to_yaml
  end

  def filter(data)
    # Custom data filtering here
  end
end

Approvals.configure do |c|
  c.approvals_path = "spec/fixtures/approvals/"
end

def print_diff(exception)
  parts = exception.message.split('"')
  received_file = parts[1]
  approved_file = parts[3]
  if File.exist?(received_file) && File.exist?(approved_file) && File.end_with?(".json")
    received_hash = JSON.parse(File.read(received_file))
    approved_hash = JSON.parse(File.read(approved_file))
    diff = Pact::Matchers.diff(approved_hash, received_hash, allow_unexpected_keys: false)
    puts Pact::Matchers::UnixDiffFormatter.call(diff)
  end
end

module MatrixQueryContentForApproval
  def matrix_query_content_for_approval(result)
    {
      "deployable" => result.deployment_status_summary.deployable?,
      "reasons" => result.deployment_status_summary.reasons.collect(&:class).collect(&:name).sort
    }
  end
end

RSpec.configure do | config |
  config.after(:each) do | example |
    if example.exception.is_a?(Approvals::ApprovalError)
      print_diff(example.exception)
    end
  end

  def file_name_to_approval_name(filename)
    sanitize_filename(filename.split("spec/lib/pact_broker/", 2).last.gsub(".rb", ""))
  end

  def sanitize_filename(filename)
    filename.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "�").strip.tr("\u{202E}%$|:;/\t\r\n\\", "-")
  end

end
