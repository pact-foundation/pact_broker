if defined? RSpec
  require 'approvals/extensions/rspec/dsl'
  require 'approvals/namers/rspec_namer'
  require 'approvals/namers/directory_namer'

  RSpec.configure do |c|
    c.include Approvals::RSpec::DSL
    c.add_setting :approvals_path, :default => 'spec/fixtures/approvals/'
    c.add_setting :approvals_namer_class, :default => Approvals::Namers::DirectoryNamer
    c.add_setting :diff_on_approval_failure, :default => false
    c.add_setting :approvals_default_format, :default => nil
  end
end
