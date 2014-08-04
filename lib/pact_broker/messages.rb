require 'i18n'

I18n.config.load_path << File.expand_path("../locale/en.yml", __FILE__)

module PactBroker
  # Provides an interface to the I18n library specifically for
  # {Webmachine}'s messages.
  module Messages
    # Interpolates an internationalized string.
    # @param [String] key the name of the string to interpolate
    # @param [Hash] options options to pass to I18n, including
    #   variables to interpolate.
    # @return [String] the interpolated string
    def message(key, options={})
      ::I18n.t(key, options.merge(:scope => :pact_broker))
    end
  end
end
