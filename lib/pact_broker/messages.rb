require "i18n"
require "pact_broker/api/pact_broker_urls"

I18n.config.load_path << File.expand_path("../locale/en.yml", __FILE__)

module PactBroker
  # Provides an interface to the I18n library specifically for
  # the PactBroker's messages.
  module Messages

    extend self

    # Interpolates an internationalized string.
    # @param [String] key the name of the string to interpolate
    # @param [Hash] options options to pass to I18n, including
    #   variables to interpolate.
    # @return [String] the interpolated string
    def message(key, options={})
      ::I18n.t(key, **{ :scope => :pact_broker }.merge(options))
    end

    def validation_message key, options = {}
      message("errors.validation." + key, options)
    end

    def pluralize(word, count)
      if count == 1
        word
      else
        if word.end_with?("y")
          word.chomp("y") + "ies"
        else
          word + "s"
        end
      end
    end
  end
end
