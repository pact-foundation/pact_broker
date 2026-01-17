module Approvals
  module Writers
    class XmlWriter < TextWriter

      def extension
        'xml'
      end

      def format(data)
        Nokogiri::XML(data.to_s.strip,&:noblanks).to_xml(:indent => 2, :encoding => 'UTF-8')
      end

    end
  end
end
