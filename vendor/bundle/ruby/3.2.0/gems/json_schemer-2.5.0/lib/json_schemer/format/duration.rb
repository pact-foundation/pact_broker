# frozen_string_literal: true
module JSONSchemer
  module Format
    module Duration
      # https://datatracker.ietf.org/doc/html/rfc3339#appendix-A
      DUR_SECOND = '\d+S'                                              # dur-second        = 1*DIGIT "S"
      DUR_MINUTE = "\\d+M(#{DUR_SECOND})?"                             # dur-minute        = 1*DIGIT "M" [dur-second]
      DUR_HOUR = "\\d+H(#{DUR_MINUTE})?"                               # dur-hour          = 1*DIGIT "H" [dur-minute]
      DUR_TIME = "T(#{DUR_HOUR}|#{DUR_MINUTE}|#{DUR_SECOND})"          # dur-time          = "T" (dur-hour / dur-minute / dur-second)
      DUR_DAY = '\d+D'                                                 # dur-day           = 1*DIGIT "D"
      DUR_WEEK = '\d+W'                                                # dur-week          = 1*DIGIT "W"
      DUR_MONTH = "\\d+M(#{DUR_DAY})?"                                 # dur-month         = 1*DIGIT "M" [dur-day]
      DUR_YEAR = "\\d+Y(#{DUR_MONTH})?"                                # dur-year          = 1*DIGIT "Y" [dur-month]
      DUR_DATE = "(#{DUR_DAY}|#{DUR_MONTH}|#{DUR_YEAR})(#{DUR_TIME})?" # dur-date          = (dur-day / dur-month / dur-year) [dur-time]
      DURATION = "P(#{DUR_DATE}|#{DUR_TIME}|#{DUR_WEEK})"              # duration          = "P" (dur-date / dur-time / dur-week)
      DURATION_REGEX = /\A#{DURATION}\z/

      def valid_duration?(data)
        DURATION_REGEX.match?(data)
      end
    end
  end
end
