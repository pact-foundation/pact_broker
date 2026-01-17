module Approvals
  module Reporters
    class HtmlImageReporter
      include Singleton

      def working_in_this_environment?
        true
      end

      def report(received, approved)
        display html(received, approved)
      end

      def html(received, approved)
        template(File.expand_path(received), File.expand_path(approved))
      end

      def display(page)
        filename = "#{Approvals.tmp_path}tmp-#{rand(Time.now.to_i)}.html"
        File.open(filename, 'w') do |file|
          file.write page
        end
        system("open #{filename}")
      end

      private
      def template(received, approved)
        <<-HTML.gsub(/^\ {8}/, '').chomp
        <html><head><title>Approval</title></head><body><center><table style="text-align: center;" border="1"><tr><td><img src="file://#{received}"></td><td><img src="file://#{approved}"></td></tr><tr><td>received</td><td>approved</td></tr></table></center></body></html>
        HTML
      end

    end
  end
end
