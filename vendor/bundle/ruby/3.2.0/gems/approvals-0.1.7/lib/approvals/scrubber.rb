module Approvals
  class Scrubber
    def initialize(string, hash = nil)
      @hash = hash
      @string = scrub(string)
    end

    def hash
      @hash ||= {
        'current_dir' => File.expand_path('.')
      }
    end

    def scrub(string)
      hash.each do |key, value|
        string = string.gsub(value, wrap(key))
      end
      string
    end

    def unscrub(string = @string)
      hash.each do |key, value|
        string = string.gsub(wrap(key), value)
      end
      string
    end

    def wrap(string)
      "{{#{string}}}"
    end

    def to_s
      @string
    end

    #def to_executable(&block)
    #  Approvals::Executable.new(@string) do |scrubbed|
    #    block.call(unscrub(scrubbed))
    #  end
    #end

  end
end
