# don't require the approvals library here, as it will reset the dotfile.
# or find a better way to reset the dotfile before a run.
module Approvals
  class CLI < Thor

    desc "verify", "Go through all failing approvals with a diff tool"
    method_option :diff, :type => :string, :default => 'diff -N', :aliases => '-d', :desc => 'The difftool to use. e.g. opendiff, vimdiff, etc.'
    method_option :ask, :type => :boolean, :default => true, :aliases => "-a", :desc => 'Offer to approve the received file for you.'
    def verify
      approvals = File.read('.approvals').split("\n")

      rejected = []
      approvals.each do |approval|
        approved, received = approval.split(/\s+/)
        if received.include?(".approved.")
          received, approved = approved, received
        end

        diff_command = "#{options[:diff]} #{approved} #{received}"
        puts diff_command
        system(diff_command)

        if options[:ask] && yes?("Approve? [y/N] ")
          system("mv #{received} #{approved}")
        else
          rejected << approval
        end
      end

      File.open('.approvals', 'w') do |f|
        f.write rejected.join("\n")
      end
    end

  end
end
