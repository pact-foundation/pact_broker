module ConventionalChangelog
  class Generator
    def generate!(options = {})
      writer(options).new("CHANGELOG.md").write! options
    end

    private

    def writer(options)
      options[:version] ? ByVersionWriter : ByDateWriter
    end
  end
end
