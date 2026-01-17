# frozen_string_literal: true
module JSONSchemer
  module Format
    module URITemplate
      # https://datatracker.ietf.org/doc/html/rfc6570
      PCT_ENCODED = '%\h{2}'                                         # pct-encoded     =  "%" HEXDIG HEXDIG
      EXPLODE = '\*'                                                 # explode         =  "*"
      MAX_LENGTH = '[1-9]\d{0,3}'                                    # max-length      =  %x31-39 0*3DIGIT   ; positive integer < 10000
      PREFIX = ":#{MAX_LENGTH}"                                      # prefix          =  ":" max-length
      MODIFIER_LEVEL4 = "#{PREFIX}|#{EXPLODE}"                       # modifier-level4 =  prefix / explode
      VARCHAR = "(\\w|#{PCT_ENCODED})"                               # varchar         =  ALPHA / DIGIT / "_" / pct-encoded
      VARNAME = "#{VARCHAR}(\\.?#{VARCHAR})*"                        # varname         =  varchar *( ["."] varchar )
      VARSPEC = "#{VARNAME}(#{MODIFIER_LEVEL4})?"                    # varspec         =  varname [ modifier-level4 ]
      VARIABLE_LIST = "#{VARSPEC}(,#{VARSPEC})*"                     # variable-list   =  varspec *( "," varspec )
      OPERATOR = '[+#./;?&=,!@|]'                                    # operator        =  op-level2 / op-level3 / op-reserve
                                                                     # op-level2       =  "+" / "#"
                                                                     # op-level3       =  "." / "/" / ";" / "?" / "&"
                                                                     # op-reserve      =  "=" / "," / "!" / "@" / "|"
      EXPRESSION = "{#{OPERATOR}?#{VARIABLE_LIST}}"                  # expression      =  "{" [ operator ] variable-list "}"
      LITERALS = "[^\\x00-\\x20\\x7F\"%'<>\\\\^`{|}]|#{PCT_ENCODED}" # literals        =  %x21 / %x23-24 / %x26 / %x28-3B / %x3D / %x3F-5B
                                                                     #                 /  %x5D / %x5F / %x61-7A / %x7E / ucschar / iprivate
                                                                     #                 /  pct-encoded
                                                                     #                      ; any Unicode character except: CTL, SP,
                                                                     #                      ;  DQUOTE, "'", "%" (aside from pct-encoded),
                                                                     #                      ;  "<", ">", "\", "^", "`", "{", "|", "}"
      URI_TEMPLATE = "(#{LITERALS}|#{EXPRESSION})*"                  # URI-Template    = *( literals / expression )
      URI_TEMPLATE_REGEX = /\A#{URI_TEMPLATE}\z/

      def valid_uri_template?(data)
        URI_TEMPLATE_REGEX.match?(data)
      end
    end
  end
end
