# frozen_string_literal: true
module JSONSchemer
  module Draft6
    module Vocab
      ALL = Draft7::Vocab::ALL.dup
      ALL.delete('$comment')
      ALL.delete('if')
      ALL.delete('then')
      ALL.delete('else')
      ALL.delete('readOnly')
      ALL.delete('writeOnly')
      ALL.delete('contentMediaType')
      ALL.delete('contentEncoding')
    end
  end
end
