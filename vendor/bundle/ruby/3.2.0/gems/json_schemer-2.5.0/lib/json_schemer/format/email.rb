# frozen_string_literal: true
module JSONSchemer
  module Format
    module Email
      # https://datatracker.ietf.org/doc/html/rfc6531#section-3.3
      # I think this is the same as "UTF8-non-ascii"? (https://datatracker.ietf.org/doc/html/rfc6532#section-3.1)
      UTF8_NON_ASCII = '[^[:ascii:]]'
      # https://datatracker.ietf.org/doc/html/rfc5321#section-4.1.2
      A_TEXT = "([\\w!#$%&'*+\\-/=?\\^`{|}~]|#{UTF8_NON_ASCII})"              # atext           = ALPHA / DIGIT /    ; Printable US-ASCII
                                                                              #                   "!" / "#" /        ;  characters not including
                                                                              #                   "$" / "%" /        ;  specials.  Used for atoms.
                                                                              #                   "&" / "'" /
                                                                              #                   "*" / "+" /
                                                                              #                   "-" / "/" /
                                                                              #                   "=" / "?" /
                                                                              #                   "^" / "_" /
                                                                              #                   "`" / "{" /
                                                                              #                   "|" / "}" /
                                                                              #                   "~"
      Q_TEXT_SMTP = "([\\x20-\\x21\\x23-\\x5B\\x5D-\\x7E]|#{UTF8_NON_ASCII})" # qtextSMTP       = %d32-33 / %d35-91 / %d93-126
                                                                              #                 ; i.e., within a quoted string, any
                                                                              #                 ; ASCII graphic or space is permitted
                                                                              #                 ; without blackslash-quoting except
                                                                              #                 ; double-quote and the backslash itself.
      QUOTED_PAIR_SMTP = '\x5C[\x20-\x7E]'                                    # quoted-pairSMTP = %d92 %d32-126
                                                                              #                 ; i.e., backslash followed by any ASCII
                                                                              #                 ; graphic (including itself) or SPace
      Q_CONTENT_SMTP = "#{Q_TEXT_SMTP}|#{QUOTED_PAIR_SMTP}"                   # QcontentSMTP    = qtextSMTP / quoted-pairSMTP
      QUOTED_STRING = "\"(#{Q_CONTENT_SMTP})*\""                              # Quoted-string   = DQUOTE *QcontentSMTP DQUOTE
      ATOM = "#{A_TEXT}+"                                                     # Atom            = 1*atext
      DOT_STRING = "#{ATOM}(\\.#{ATOM})*"                                     # Dot-string      = Atom *("."  Atom)
      LOCAL_PART = "#{DOT_STRING}|#{QUOTED_STRING}"                           # Local-part      = Dot-string / Quoted-string
                                                                              #                 ; MAY be case-sensitive
                                                                              # IPv4-address-literal  = Snum 3("."  Snum)
      # using `valid_id?` to check ip addresses because it's complicated.     # IPv6-address-literal  = "IPv6:" IPv6-addr
      ADDRESS_LITERAL = '\[(IPv6:(?<ipv6>[\h:]+)|(?<ipv4>[\d.]+))\]'          # address-literal = "[" ( IPv4-address-literal /
                                                                              #                 IPv6-address-literal /
                                                                              #                 General-address-literal ) "]"
                                                                              #                 ; See Section 4.1.3
      # using `valid_hostname?` to check domain because it's complicated
      MAILBOX = "(#{LOCAL_PART})@(#{ADDRESS_LITERAL}|(?<domain>.+))"          # Mailbox         = Local-part "@" ( Domain / address-literal )
      EMAIL_REGEX = /\A#{MAILBOX}\z/

      def valid_email?(data)
        return false unless match = EMAIL_REGEX.match(data)
        if ipv4 = match.named_captures.fetch('ipv4')
          valid_ip?(ipv4, Socket::AF_INET)
        elsif ipv6 = match.named_captures.fetch('ipv6')
          valid_ip?(ipv6, Socket::AF_INET6)
        else
          valid_hostname?(match.named_captures.fetch('domain'))
        end
      end
    end
  end
end
