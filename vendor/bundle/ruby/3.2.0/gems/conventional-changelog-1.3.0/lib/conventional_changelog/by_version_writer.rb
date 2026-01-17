module ConventionalChangelog
  class ByVersionWriter < Writer
    private

    def filter_key
      :since_version
    end

    def build_new_lines(options)
      write_section commits, options[:version]
    end

    def version_header_title(id)
      "#{id} (#{commits[0][:date]})"
    end
  end
end
