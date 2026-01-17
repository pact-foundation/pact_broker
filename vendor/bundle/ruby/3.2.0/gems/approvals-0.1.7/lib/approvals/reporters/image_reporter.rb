module Approvals
  module Reporters

    class ImageReporter < FirstWorkingReporter
      include Singleton

      def initialize
        super(ImageMagickReporter.instance, HtmlImageReporter.instance)
      end
    end

  end
end
