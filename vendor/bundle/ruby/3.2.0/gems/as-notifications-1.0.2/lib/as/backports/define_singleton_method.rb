# From https://github.com/marcandre/backports
# backports is released under the terms of the MIT License, see the included
# LICENSE file.
unless Kernel.method_defined? :define_singleton_method
  module Kernel
    def define_singleton_method(*args, &block)
      class << self
        self
      end.send(:define_method, *args, &block)
    end
  end
end
