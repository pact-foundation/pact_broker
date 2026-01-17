# frozen_string_literal: true

# Moments::Version module
module Moments
  def self.gem_version
    Gem::Version.new VERSION::STRING
  end

  # Moments version builder module
  module VERSION
    # major version
    MAJOR = 0
    # minor version
    MINOR = 3
    # patch version
    PATCH = 0
    # alpha, beta, etc. tag
    PRE   = nil

    # Build version string
    STRING = [MAJOR, MINOR, PATCH, PRE].compact.join('.')
  end
end
