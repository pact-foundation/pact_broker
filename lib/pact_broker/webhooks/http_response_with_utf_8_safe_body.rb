module PactBroker
  module Webhooks
    class HttpResponseWithUtf8SafeBody < SimpleDelegator
      def body
        if unsafe_body
          unsafe_body.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
        else
          unsafe_body
        end
      end

      def unsafe_body
        __getobj__().body
      end

      def unsafe_body?
        unsafe_body != body
      end
    end
  end
end
