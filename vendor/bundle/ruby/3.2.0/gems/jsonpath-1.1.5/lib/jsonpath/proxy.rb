# frozen_string_literal: true

class JsonPath
  class Proxy
    attr_reader :obj
    alias to_hash obj

    def initialize(obj)
      @obj = obj
    end

    def gsub(path, replacement = nil, &replacement_block)
      _gsub(_deep_copy, path, replacement ? proc(&method(:replacement)) : replacement_block)
    end

    def gsub!(path, replacement = nil, &replacement_block)
      _gsub(@obj, path, replacement ? proc(&method(:replacement)) : replacement_block)
    end

    def delete(path = JsonPath::PATH_ALL)
      _delete(_deep_copy, path)
    end

    def delete!(path = JsonPath::PATH_ALL)
      _delete(@obj, path)
    end

    def compact(path = JsonPath::PATH_ALL)
      _compact(_deep_copy, path)
    end

    def compact!(path = JsonPath::PATH_ALL)
      _compact(@obj, path)
    end

    private

    def _deep_copy
      Marshal.load(Marshal.dump(@obj))
    end

    def _gsub(obj, path, replacement)
      JsonPath.new(path)[obj, :substitute].each(&replacement)
      Proxy.new(obj)
    end

    def _delete(obj, path)
      JsonPath.new(path)[obj, :delete].each
      obj = _remove(obj)
      Proxy.new(obj)
    end

    def _remove(obj)
      obj.each do |o|
        if o.is_a?(Hash) || o.is_a?(Array)
          _remove(o)
          o.delete({})
        end
      end
    end

    def _compact(obj, path)
      JsonPath.new(path)[obj, :compact].each
      Proxy.new(obj)
    end
  end
end
