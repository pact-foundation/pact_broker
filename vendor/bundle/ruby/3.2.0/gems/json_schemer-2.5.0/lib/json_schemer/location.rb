# frozen_string_literal: true
module JSONSchemer
  module Location
    JSON_POINTER_TOKEN_ESCAPE_CHARS = { '~' => '~0', '/' => '~1' }
    JSON_POINTER_TOKEN_ESCAPE_REGEX = Regexp.union(JSON_POINTER_TOKEN_ESCAPE_CHARS.keys)

    class << self
      def root
        {}
      end

      def join(location, name)
        location[name] ||= { :name => name, :parent => location }
      end

      def resolve(location)
        location[:resolve] ||= location[:parent] ? "#{resolve(location[:parent])}/#{escape_json_pointer_token(location[:name])}" : ''
      end

      def escape_json_pointer_token(token)
        token.gsub(JSON_POINTER_TOKEN_ESCAPE_REGEX, JSON_POINTER_TOKEN_ESCAPE_CHARS)
      end
    end
  end
end
