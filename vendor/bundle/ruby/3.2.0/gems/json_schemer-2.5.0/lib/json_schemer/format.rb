# frozen_string_literal: true
module JSONSchemer
  module Format
    # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-validation-01#section-7.3
    DATE_TIME = proc do |instance, _format|
      !instance.is_a?(String) || valid_date_time?(instance)
    end
    DATE = proc do |instance, _format|
      !instance.is_a?(String) || valid_date_time?("#{instance}T04:05:06.123456789+07:00")
    end
    TIME = proc do |instance, _format|
      !instance.is_a?(String) || valid_date_time?("2001-02-03T#{instance}")
    end
    DURATION = proc do |instance, _format|
      !instance.is_a?(String) || valid_duration?(instance)
    end
    # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-validation-01#section-7.3.2
    EMAIL = proc do |instance, _format|
      !instance.is_a?(String) || instance.ascii_only? && valid_email?(instance)
    end
    IDN_EMAIL = proc do |instance, _format|
      !instance.is_a?(String) || valid_email?(instance)
    end
    # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-validation-01#section-7.3.3
    HOSTNAME = proc do |instance, _format|
      !instance.is_a?(String) || instance.ascii_only? && valid_hostname?(instance)
    end
    IDN_HOSTNAME = proc do |instance, _format|
      !instance.is_a?(String) || valid_hostname?(instance)
    end
    # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-validation-01#section-7.3.4
    IPV4 = proc do |instance, _format|
      !instance.is_a?(String) || valid_ip?(instance, Socket::AF_INET)
    end
    IPV6 = proc do |instance, _format|
      !instance.is_a?(String) || valid_ip?(instance, Socket::AF_INET6)
    end
    # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-validation-01#section-7.3.5
    URI = proc do |instance, _format|
      !instance.is_a?(String) || valid_uri?(instance)
    end
    URI_REFERENCE = proc do |instance, _format|
      !instance.is_a?(String) || valid_uri_reference?(instance)
    end
    IRI = proc do |instance, _format|
      !instance.is_a?(String) || valid_uri?(iri_escape(instance))
    end
    IRI_REFERENCE = proc do |instance, _format|
      !instance.is_a?(String) || valid_uri_reference?(iri_escape(instance))
    end
    UUID = proc do |instance, _format|
      !instance.is_a?(String) || valid_uuid?(instance)
    end
    # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-validation-01#section-7.3.6
    URI_TEMPLATE = proc do |instance, _format|
      !instance.is_a?(String) || valid_uri_template?(instance)
    end
    # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-validation-01#section-7.3.7
    JSON_POINTER = proc do |instance, _format|
      !instance.is_a?(String) || valid_json_pointer?(instance)
    end
    RELATIVE_JSON_POINTER = proc do |instance, _format|
      !instance.is_a?(String) || valid_relative_json_pointer?(instance)
    end
    # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-validation-01#section-7.3.8
    REGEX = proc do |instance, _format|
      !instance.is_a?(String) || valid_regex?(instance)
    end

    DATE_TIME_OFFSET_REGEX = /(Z|[\+\-]([01][0-9]|2[0-3]):[0-5][0-9])\z/i.freeze
    DATE_TIME_SEPARATOR_CHARACTER_CLASS = '[Tt\s]'
    HOUR_24_REGEX = /#{DATE_TIME_SEPARATOR_CHARACTER_CLASS}24:/.freeze
    LEAP_SECOND_REGEX = /#{DATE_TIME_SEPARATOR_CHARACTER_CLASS}\d{2}:\d{2}:6/.freeze
    IP_REGEX = /\A[\h:.]+\z/.freeze
    INVALID_QUERY_REGEX = /\s/.freeze
    IRI_ESCAPE_REGEX = /[^[:ascii:]]/
    UUID_REGEX = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/i
    NIL_UUID = '00000000-0000-0000-0000-000000000000'
    BINARY_TO_PERCENT_ENCODED = 256.times.each_with_object({}) do |byte, out|
      out[-byte.chr(Encoding::BINARY)] = -sprintf('%%%02X', byte)
    end.freeze

    class << self
      include Duration
      include Email
      include Hostname
      include JSONPointer
      include URITemplate

      def percent_encode(data, regexp)
        binary = data.b
        binary.gsub!(regexp, BINARY_TO_PERCENT_ENCODED)
        binary.force_encoding(data.encoding)
      end

      def valid_date_time?(data)
        return false if HOUR_24_REGEX.match?(data)
        datetime = DateTime.rfc3339(data)
        return false if LEAP_SECOND_REGEX.match?(data) && datetime.new_offset.strftime('%H:%M') != '23:59'
        DATE_TIME_OFFSET_REGEX.match?(data)
      rescue ArgumentError
        false
      end

      def valid_ip?(data, family)
        IPAddr.new(data, family)
        IP_REGEX.match?(data)
      rescue IPAddr::Error
        false
      end

      def parse_uri_scheme(data)
        scheme, _userinfo, _host, _port, _registry, _path, opaque, query, _fragment = ::URI::RFC3986_PARSER.split(data)
        # ::URI::RFC3986_PARSER.parse allows spaces in these and I don't think it should
        raise ::URI::InvalidURIError if INVALID_QUERY_REGEX.match?(query) || INVALID_QUERY_REGEX.match?(opaque)
        scheme
      end

      def valid_uri?(data)
        !!parse_uri_scheme(data)
      rescue ::URI::InvalidURIError
        false
      end

      def valid_uri_reference?(data)
        parse_uri_scheme(data)
        true
      rescue ::URI::InvalidURIError
        false
      end

      def iri_escape(data)
        Format.percent_encode(data, IRI_ESCAPE_REGEX)
      end

      def valid_regex?(data)
        !!EcmaRegexp.ruby_equivalent(data)
      rescue InvalidEcmaRegexp
        false
      end

      def valid_uuid?(data)
        UUID_REGEX.match?(data) || NIL_UUID == data
      end
    end
  end
end
