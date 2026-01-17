module Approvals

  class Dotfile
    class << self

      def reset
        File.truncate(path, 0) if File.exist?(path)
      end

      def append(text)
        unless includes?(text)
          write text
        end
      end

      private

      def path
        File.join(Approvals.project_dir, '.approvals')
      end

      def includes?(text)
        system("cat #{path} 2> /dev/null | grep -q \"^#{text}$\"")
      end

      def write(text)
        File.open(path, 'a+') do |f|
          f.write "#{text}\n"
        end
      end
    end
  end
end
