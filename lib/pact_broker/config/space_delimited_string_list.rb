module PactBroker
  module Config
    class SpaceDelimitedStringList < Array

      def initialize list
        super(list)
      end

      def self.parse(string)
        array = (string || "").split(" ").collect do | word |
          if word[0] == "/" and word[-1] == "/"
            Regexp.new(word[1..-2])
          else
            word
          end
        end
        SpaceDelimitedStringList.new(array)
      end

      def to_s
        collect do | word |
          if word.is_a?(Regexp)
            "/#{word.source}/"
          else
            word
          end
        end.join(" ")
      end
    end
  end
end
