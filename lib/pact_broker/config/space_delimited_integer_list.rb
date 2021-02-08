module PactBroker
  module Config
    class SpaceDelimitedIntegerList < Array
      def initialize list
        super(list)
      end

      def self.integer?(string)
        (Integer(string) rescue nil) != nil
      end

      def self.parse(string)
        array = (string || '')
                    .split(' ')
                    .filter { |word| integer?(word) }
                    .collect(&:to_i)
        SpaceDelimitedIntegerList.new(array)
      end

      def to_s
        collect(&:to_s).join(' ')
      end
    end
  end
end
