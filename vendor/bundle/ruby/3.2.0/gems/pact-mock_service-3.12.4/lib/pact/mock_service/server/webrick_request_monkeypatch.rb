module WEBrick
  class HTTPRequest
    alias_method :pact_original_meta_vars, :meta_vars

    def meta_vars
      original_underscored_headers = []
      self.each{|key, val| original_underscored_headers << key if key.include?("_") }
      # This header allows us to restore the original format (eg. underscored) of the headers
      # when parsing the incoming Rack env back to a response object.
      vars = pact_original_meta_vars
      vars["X_PACT_UNDERSCORED_HEADER_NAMES"] = original_underscored_headers.join(",")
      vars
    end
  end
end
