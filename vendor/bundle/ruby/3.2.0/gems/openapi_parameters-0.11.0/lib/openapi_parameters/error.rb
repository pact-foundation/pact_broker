# frozen_string_literal: true

module OpenapiParameters
  class Error < StandardError
  end

  class NotSupportetError < Error
  end

  InvalidParameterError = Rack::Utils::InvalidParameterError
end
