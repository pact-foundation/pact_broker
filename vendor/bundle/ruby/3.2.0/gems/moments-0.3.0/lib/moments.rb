# frozen_string_literal: true

require_relative 'moments/version'
require_relative 'moments/difference'

# Entrypoint for the moments gem
module Moments
  def self.difference(from, to, mode = :normal)
    Moments::Difference.new from, to, mode
  end

  def self.ago(from, mode = :normal)
    Moments::Difference.new from, Time.now, mode
  end
end
