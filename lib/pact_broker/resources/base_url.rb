module PactBroker
  module Resources
    module BaseUrl
      def base_url
        request.uri.to_s.gsub(/#{request.uri.path}$/,'')
      end
    end
  end
end