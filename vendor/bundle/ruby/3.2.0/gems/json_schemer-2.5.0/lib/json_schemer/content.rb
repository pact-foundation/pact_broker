# frozen_string_literal: true
module JSONSchemer
  module ContentEncoding
    BASE64 = proc do |instance|
      [true, instance.unpack1("m0")]
    rescue
      [false, nil]
    end
  end

  module ContentMediaType
    JSON = proc do |instance|
      [true, ::JSON.parse(instance)]
    rescue
      [false, nil]
    end
  end
end
