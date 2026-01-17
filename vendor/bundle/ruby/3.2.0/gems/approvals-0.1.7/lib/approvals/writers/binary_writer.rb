module Approvals
  module Writers
    class BinaryWriter
      EXCEPTION_WRITER = Proc.new do |data, file|
        raise "BinaryWriter#callback missing"
      end

      def initialize(opts = {})
        @autoregister = opts[:autoregister] || true
        @detect = opts[:detect]
        @extension = opts[:extension] || ''
        @write = opts[:write] || EXCEPTION_WRITER
        self.format = opts[:format] || :binary
      end

      attr_reader :format

      def format=(sym)
        unregister if autoregister

        @format = sym

        register if autoregister

      end

      def register
        if @format
          Writer::REGISTRY[@format] = self
          Approval::BINARY_FORMATS << @format
          Approval::IDENTITIES[@format] = @detect if @detect
        end
      end

      def unregister
        if @format
          Writer::REGISTRY.delete!(@format)
          Approval::BINARY_FORMATS.delete!(@format)
          Approval::IDENTITIES.delete!(@format)
        end
      end

      def write(data,path)
        @write.call(data,path)
      end

    end
  end
end
