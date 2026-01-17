module Pact
  class SpecificationVersion < Gem::Version

    def major
      segments.first
    end

    def === other
      major && major == other
    end

    def after? other
      major && other < major
    end
  end

  SpecificationVersion::NIL_VERSION = Pact::SpecificationVersion.new('0')
end
