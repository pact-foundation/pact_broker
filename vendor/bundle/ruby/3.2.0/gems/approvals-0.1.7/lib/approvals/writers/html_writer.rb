module Approvals
  module Writers
    class HtmlWriter < TextWriter

      def extension
        'html'
      end

      def format(data)
        Nokogiri::HTML(data.to_s.strip,&:noblanks).to_xhtml(:indent => 2, :encoding => 'UTF-8')
      end

    end
  end
end
