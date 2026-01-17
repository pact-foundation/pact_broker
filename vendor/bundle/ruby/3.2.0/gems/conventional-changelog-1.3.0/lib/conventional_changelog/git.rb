require 'open3'

module ConventionalChangelog
  class Git
    DELIMITER = "/////"

    def self.commits(options)
      log(options).split("\n").map { |commit| commit.split DELIMITER }.select { |commit| options[:since_date].nil? or commit[1] > options[:since_date] }.map do |commit|
        comment = commit[2].match(/(\w*)(\(([\w\$\.\-\* ]*)\))?\: (.*)/)
        next unless comment
        { id: commit[0], date: commit[1], type: comment[1], component: comment[3], change: comment[4] }
      end.compact
    end

    def self.log(options)
      output, status = Open3.capture2(%Q{
        git log \
          --pretty=format:"%h#{DELIMITER}%ad#{DELIMITER}%s%x09" --date=short \
          --grep="^(feat|fix)(\\(.*\\))?:" -E \
          #{version_filter(options)}
      })

      if status.success?
        output
      else
        raise "Can't load Git commits, check your arguments"
      end
    end

    def self.version_filter(options)
      options[:since_version] ? "#{options[:since_version]}..HEAD" : ""
    end
  end
end
