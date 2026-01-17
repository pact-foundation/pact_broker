# frozen_string_literal: true
module JSONSchemer
  module Format
    module Hostname
      # https://datatracker.ietf.org/doc/html/rfc5892#section-2.1
      MARKS = '\p{Mn}\p{Mc}'
      LETTER_DIGITS = "\\p{Ll}\\p{Lu}\\p{Lo}\\p{Nd}\\p{Lm}#{MARKS}"
      # https://datatracker.ietf.org/doc/html/rfc5892#section-2.6
      EXCEPTIONS_PVALID = '\u{06FD}\u{06FE}\u{0F0B}\u{3007}' # \u{00DF}\u{03C2} covered by \p{Ll}
      EXCEPTIONS_DISALLOWED = '\u{0640}\u{07FA}\u{302E}\u{302F}\u{3031}\u{3032}\u{3033}\u{3034}\u{3035}\u{303B}'
      LABEL_CHARACTER_CLASS = "[#{LETTER_DIGITS}#{EXCEPTIONS_PVALID}&&[^#{EXCEPTIONS_DISALLOWED}]]"
      # https://datatracker.ietf.org/doc/html/rfc5891#section-4.2.3.2
      LEADING_CHARACTER_CLASS = "[#{LABEL_CHARACTER_CLASS}&&[^#{MARKS}]]"
      LABEL_REGEX_STRING = "#{LEADING_CHARACTER_CLASS}([#{LABEL_CHARACTER_CLASS}\-]*#{LABEL_CHARACTER_CLASS})?"
      # https://datatracker.ietf.org/doc/html/rfc3490#section-3.1
      LABEL_SEPARATOR_CHARACTER_CLASS = '[\u{002E}\u{3002}\u{FF0E}\u{FF61}]'
      LABEL_SEPARATOR_REGEX = /#{LABEL_SEPARATOR_CHARACTER_CLASS}/.freeze
      HOSTNAME_REGEX = /\A(#{LABEL_REGEX_STRING}#{LABEL_SEPARATOR_CHARACTER_CLASS})*#{LABEL_REGEX_STRING}\z/i.freeze
      # bin/hostname_character_classes
      VIRAMA_CHARACTER_CLASS = '[\u{094D}\u{09CD}\u{0A4D}\u{0ACD}\u{0B4D}\u{0BCD}\u{0C4D}\u{0CCD}\u{0D3B}\u{0D3C}\u{0D4D}\u{0DCA}\u{0E3A}\u{0EBA}\u{0F84}\u{1039}\u{103A}\u{1714}\u{1715}\u{1734}\u{17D2}\u{1A60}\u{1B44}\u{1BAA}\u{1BAB}\u{1BF2}\u{1BF3}\u{2D7F}\u{A806}\u{A82C}\u{A8C4}\u{A953}\u{A9C0}\u{AAF6}\u{ABED}\u{10A3F}\u{11046}\u{11070}\u{1107F}\u{110B9}\u{11133}\u{11134}\u{111C0}\u{11235}\u{112EA}\u{1134D}\u{113CE}\u{113CF}\u{113D0}\u{11442}\u{114C2}\u{115BF}\u{1163F}\u{116B6}\u{1172B}\u{11839}\u{1193D}\u{1193E}\u{119E0}\u{11A34}\u{11A47}\u{11A99}\u{11C3F}\u{11D44}\u{11D45}\u{11D97}\u{11F41}\u{11F42}\u{1612F}]'
      JOINING_TYPE_L_CHARACTER_CLASS = '[\u{A872}\u{10ACD}\u{10AD7}\u{10D00}\u{10FCB}]'
      JOINING_TYPE_D_CHARACTER_CLASS = '[\u{0620}\u{0626}\u{0628}\u{062A}-\u{062E}\u{0633}-\u{063F}\u{0641}-\u{0647}\u{0649}-\u{064A}\u{066E}-\u{066F}\u{0678}-\u{0687}\u{069A}-\u{06BF}\u{06C1}-\u{06C2}\u{06CC}\u{06CE}\u{06D0}-\u{06D1}\u{06FA}-\u{06FC}\u{06FF}\u{0712}-\u{0714}\u{071A}-\u{071D}\u{071F}-\u{0727}\u{0729}\u{072B}\u{072D}-\u{072E}\u{074E}-\u{0758}\u{075C}-\u{076A}\u{076D}-\u{0770}\u{0772}\u{0775}-\u{0777}\u{077A}-\u{077F}\u{07CA}-\u{07EA}\u{0841}-\u{0845}\u{0848}\u{084A}-\u{0853}\u{0855}\u{0860}\u{0862}-\u{0865}\u{0868}\u{0886}\u{0889}-\u{088D}\u{088F}\u{08A0}-\u{08A9}\u{08AF}-\u{08B0}\u{08B3}-\u{08B8}\u{08BA}-\u{08C8}\u{1807}\u{1820}-\u{1842}\u{1843}\u{1844}-\u{1878}\u{1887}-\u{18A8}\u{18AA}\u{A840}-\u{A871}\u{10AC0}-\u{10AC4}\u{10AD3}-\u{10AD6}\u{10AD8}-\u{10ADC}\u{10ADE}-\u{10AE0}\u{10AEB}-\u{10AEE}\u{10B80}\u{10B82}\u{10B86}-\u{10B88}\u{10B8A}-\u{10B8B}\u{10B8D}\u{10B90}\u{10BAD}-\u{10BAE}\u{10D01}-\u{10D21}\u{10D23}\u{10EC3}-\u{10EC4}\u{10EC6}-\u{10EC7}\u{10F30}-\u{10F32}\u{10F34}-\u{10F44}\u{10F51}-\u{10F53}\u{10F70}-\u{10F73}\u{10F76}-\u{10F81}\u{10FB0}\u{10FB2}-\u{10FB3}\u{10FB8}\u{10FBB}-\u{10FBC}\u{10FBE}-\u{10FBF}\u{10FC1}\u{10FC4}\u{10FCA}\u{1E900}-\u{1E943}]'
      JOINING_TYPE_T_CHARACTER_CLASS = '[\u{00AD}\u{0300}-\u{036F}\u{0483}-\u{0487}\u{0488}-\u{0489}\u{0591}-\u{05BD}\u{05BF}\u{05C1}-\u{05C2}\u{05C4}-\u{05C5}\u{05C7}\u{0610}-\u{061A}\u{061C}\u{064B}-\u{065F}\u{0670}\u{06D6}-\u{06DC}\u{06DF}-\u{06E4}\u{06E7}-\u{06E8}\u{06EA}-\u{06ED}\u{070F}\u{0711}\u{0730}-\u{074A}\u{07A6}-\u{07B0}\u{07EB}-\u{07F3}\u{07FD}\u{0816}-\u{0819}\u{081B}-\u{0823}\u{0825}-\u{0827}\u{0829}-\u{082D}\u{0859}-\u{085B}\u{0897}-\u{089F}\u{08CA}-\u{08E1}\u{08E3}-\u{0902}\u{093A}\u{093C}\u{0941}-\u{0948}\u{094D}\u{0951}-\u{0957}\u{0962}-\u{0963}\u{0981}\u{09BC}\u{09C1}-\u{09C4}\u{09CD}\u{09E2}-\u{09E3}\u{09FE}\u{0A01}-\u{0A02}\u{0A3C}\u{0A41}-\u{0A42}\u{0A47}-\u{0A48}\u{0A4B}-\u{0A4D}\u{0A51}\u{0A70}-\u{0A71}\u{0A75}\u{0A81}-\u{0A82}\u{0ABC}\u{0AC1}-\u{0AC5}\u{0AC7}-\u{0AC8}\u{0ACD}\u{0AE2}-\u{0AE3}\u{0AFA}-\u{0AFF}\u{0B01}\u{0B3C}\u{0B3F}\u{0B41}-\u{0B44}\u{0B4D}\u{0B55}-\u{0B56}\u{0B62}-\u{0B63}\u{0B82}\u{0BC0}\u{0BCD}\u{0C00}\u{0C04}\u{0C3C}\u{0C3E}-\u{0C40}\u{0C46}-\u{0C48}\u{0C4A}-\u{0C4D}\u{0C55}-\u{0C56}\u{0C62}-\u{0C63}\u{0C81}\u{0CBC}\u{0CBF}\u{0CC6}\u{0CCC}-\u{0CCD}\u{0CE2}-\u{0CE3}\u{0D00}-\u{0D01}\u{0D3B}-\u{0D3C}\u{0D41}-\u{0D44}\u{0D4D}\u{0D62}-\u{0D63}\u{0D81}\u{0DCA}\u{0DD2}-\u{0DD4}\u{0DD6}\u{0E31}\u{0E34}-\u{0E3A}\u{0E47}-\u{0E4E}\u{0EB1}\u{0EB4}-\u{0EBC}\u{0EC8}-\u{0ECE}\u{0F18}-\u{0F19}\u{0F35}\u{0F37}\u{0F39}\u{0F71}-\u{0F7E}\u{0F80}-\u{0F84}\u{0F86}-\u{0F87}\u{0F8D}-\u{0F97}\u{0F99}-\u{0FBC}\u{0FC6}\u{102D}-\u{1030}\u{1032}-\u{1037}\u{1039}-\u{103A}\u{103D}-\u{103E}\u{1058}-\u{1059}\u{105E}-\u{1060}\u{1071}-\u{1074}\u{1082}\u{1085}-\u{1086}\u{108D}\u{109D}\u{135D}-\u{135F}\u{1712}-\u{1714}\u{1732}-\u{1733}\u{1752}-\u{1753}\u{1772}-\u{1773}\u{17B4}-\u{17B5}\u{17B7}-\u{17BD}\u{17C6}\u{17C9}-\u{17D3}\u{17DD}\u{180B}-\u{180D}\u{180F}\u{1885}-\u{1886}\u{18A9}\u{1920}-\u{1922}\u{1927}-\u{1928}\u{1932}\u{1939}-\u{193B}\u{1A17}-\u{1A18}\u{1A1B}\u{1A56}\u{1A58}-\u{1A5E}\u{1A60}\u{1A62}\u{1A65}-\u{1A6C}\u{1A73}-\u{1A7C}\u{1A7F}\u{1AB0}-\u{1ABD}\u{1ABE}\u{1ABF}-\u{1ADD}\u{1AE0}-\u{1AEB}\u{1B00}-\u{1B03}\u{1B34}\u{1B36}-\u{1B3A}\u{1B3C}\u{1B42}\u{1B6B}-\u{1B73}\u{1B80}-\u{1B81}\u{1BA2}-\u{1BA5}\u{1BA8}-\u{1BA9}\u{1BAB}-\u{1BAD}\u{1BE6}\u{1BE8}-\u{1BE9}\u{1BED}\u{1BEF}-\u{1BF1}\u{1C2C}-\u{1C33}\u{1C36}-\u{1C37}\u{1CD0}-\u{1CD2}\u{1CD4}-\u{1CE0}\u{1CE2}-\u{1CE8}\u{1CED}\u{1CF4}\u{1CF8}-\u{1CF9}\u{1DC0}-\u{1DFF}\u{200B}\u{200E}-\u{200F}\u{202A}-\u{202E}\u{2060}-\u{2064}\u{206A}-\u{206F}\u{20D0}-\u{20DC}\u{20DD}-\u{20E0}\u{20E1}\u{20E2}-\u{20E4}\u{20E5}-\u{20F0}\u{2CEF}-\u{2CF1}\u{2D7F}\u{2DE0}-\u{2DFF}\u{302A}-\u{302D}\u{3099}-\u{309A}\u{A66F}\u{A670}-\u{A672}\u{A674}-\u{A67D}\u{A69E}-\u{A69F}\u{A6F0}-\u{A6F1}\u{A802}\u{A806}\u{A80B}\u{A825}-\u{A826}\u{A82C}\u{A8C4}-\u{A8C5}\u{A8E0}-\u{A8F1}\u{A8FF}\u{A926}-\u{A92D}\u{A947}-\u{A951}\u{A980}-\u{A982}\u{A9B3}\u{A9B6}-\u{A9B9}\u{A9BC}-\u{A9BD}\u{A9E5}\u{AA29}-\u{AA2E}\u{AA31}-\u{AA32}\u{AA35}-\u{AA36}\u{AA43}\u{AA4C}\u{AA7C}\u{AAB0}\u{AAB2}-\u{AAB4}\u{AAB7}-\u{AAB8}\u{AABE}-\u{AABF}\u{AAC1}\u{AAEC}-\u{AAED}\u{AAF6}\u{ABE5}\u{ABE8}\u{ABED}\u{FB1E}\u{FE00}-\u{FE0F}\u{FE20}-\u{FE2F}\u{FEFF}\u{FFF9}-\u{FFFB}\u{101FD}\u{102E0}\u{10376}-\u{1037A}\u{10A01}-\u{10A03}\u{10A05}-\u{10A06}\u{10A0C}-\u{10A0F}\u{10A38}-\u{10A3A}\u{10A3F}\u{10AE5}-\u{10AE6}\u{10D24}-\u{10D27}\u{10D69}-\u{10D6D}\u{10EAB}-\u{10EAC}\u{10EFA}-\u{10EFF}\u{10F46}-\u{10F50}\u{10F82}-\u{10F85}\u{11001}\u{11038}-\u{11046}\u{11070}\u{11073}-\u{11074}\u{1107F}-\u{11081}\u{110B3}-\u{110B6}\u{110B9}-\u{110BA}\u{110C2}\u{11100}-\u{11102}\u{11127}-\u{1112B}\u{1112D}-\u{11134}\u{11173}\u{11180}-\u{11181}\u{111B6}-\u{111BE}\u{111C9}-\u{111CC}\u{111CF}\u{1122F}-\u{11231}\u{11234}\u{11236}-\u{11237}\u{1123E}\u{11241}\u{112DF}\u{112E3}-\u{112EA}\u{11300}-\u{11301}\u{1133B}-\u{1133C}\u{11340}\u{11366}-\u{1136C}\u{11370}-\u{11374}\u{113BB}-\u{113C0}\u{113CE}\u{113D0}\u{113D2}\u{113E1}-\u{113E2}\u{11438}-\u{1143F}\u{11442}-\u{11444}\u{11446}\u{1145E}\u{114B3}-\u{114B8}\u{114BA}\u{114BF}-\u{114C0}\u{114C2}-\u{114C3}\u{115B2}-\u{115B5}\u{115BC}-\u{115BD}\u{115BF}-\u{115C0}\u{115DC}-\u{115DD}\u{11633}-\u{1163A}\u{1163D}\u{1163F}-\u{11640}\u{116AB}\u{116AD}\u{116B0}-\u{116B5}\u{116B7}\u{1171D}\u{1171F}\u{11722}-\u{11725}\u{11727}-\u{1172B}\u{1182F}-\u{11837}\u{11839}-\u{1183A}\u{1193B}-\u{1193C}\u{1193E}\u{11943}\u{119D4}-\u{119D7}\u{119DA}-\u{119DB}\u{119E0}\u{11A01}-\u{11A0A}\u{11A33}-\u{11A38}\u{11A3B}-\u{11A3E}\u{11A47}\u{11A51}-\u{11A56}\u{11A59}-\u{11A5B}\u{11A8A}-\u{11A96}\u{11A98}-\u{11A99}\u{11B60}\u{11B62}-\u{11B64}\u{11B66}\u{11C30}-\u{11C36}\u{11C38}-\u{11C3D}\u{11C3F}\u{11C92}-\u{11CA7}\u{11CAA}-\u{11CB0}\u{11CB2}-\u{11CB3}\u{11CB5}-\u{11CB6}\u{11D31}-\u{11D36}\u{11D3A}\u{11D3C}-\u{11D3D}\u{11D3F}-\u{11D45}\u{11D47}\u{11D90}-\u{11D91}\u{11D95}\u{11D97}\u{11EF3}-\u{11EF4}\u{11F00}-\u{11F01}\u{11F36}-\u{11F3A}\u{11F40}\u{11F42}\u{11F5A}\u{13430}-\u{1343F}\u{13440}\u{13447}-\u{13455}\u{1611E}-\u{16129}\u{1612D}-\u{1612F}\u{16AF0}-\u{16AF4}\u{16B30}-\u{16B36}\u{16F4F}\u{16F8F}-\u{16F92}\u{16FE4}\u{1BC9D}-\u{1BC9E}\u{1BCA0}-\u{1BCA3}\u{1CF00}-\u{1CF2D}\u{1CF30}-\u{1CF46}\u{1D167}-\u{1D169}\u{1D173}-\u{1D17A}\u{1D17B}-\u{1D182}\u{1D185}-\u{1D18B}\u{1D1AA}-\u{1D1AD}\u{1D242}-\u{1D244}\u{1DA00}-\u{1DA36}\u{1DA3B}-\u{1DA6C}\u{1DA75}\u{1DA84}\u{1DA9B}-\u{1DA9F}\u{1DAA1}-\u{1DAAF}\u{1E000}-\u{1E006}\u{1E008}-\u{1E018}\u{1E01B}-\u{1E021}\u{1E023}-\u{1E024}\u{1E026}-\u{1E02A}\u{1E08F}\u{1E130}-\u{1E136}\u{1E2AE}\u{1E2EC}-\u{1E2EF}\u{1E4EC}-\u{1E4EF}\u{1E5EE}-\u{1E5EF}\u{1E6E3}\u{1E6E6}\u{1E6EE}-\u{1E6EF}\u{1E6F5}\u{1E8D0}-\u{1E8D6}\u{1E944}-\u{1E94A}\u{1E94B}\u{E0001}\u{E0020}-\u{E007F}\u{E0100}-\u{E01EF}]'
      JOINING_TYPE_R_CHARACTER_CLASS = '[\u{0622}-\u{0625}\u{0627}\u{0629}\u{062F}-\u{0632}\u{0648}\u{0671}-\u{0673}\u{0675}-\u{0677}\u{0688}-\u{0699}\u{06C0}\u{06C3}-\u{06CB}\u{06CD}\u{06CF}\u{06D2}-\u{06D3}\u{06D5}\u{06EE}-\u{06EF}\u{0710}\u{0715}-\u{0719}\u{071E}\u{0728}\u{072A}\u{072C}\u{072F}\u{074D}\u{0759}-\u{075B}\u{076B}-\u{076C}\u{0771}\u{0773}-\u{0774}\u{0778}-\u{0779}\u{0840}\u{0846}-\u{0847}\u{0849}\u{0854}\u{0856}-\u{0858}\u{0867}\u{0869}-\u{086A}\u{0870}-\u{0882}\u{088E}\u{08AA}-\u{08AC}\u{08AE}\u{08B1}-\u{08B2}\u{08B9}\u{10AC5}\u{10AC7}\u{10AC9}-\u{10ACA}\u{10ACE}-\u{10AD2}\u{10ADD}\u{10AE1}\u{10AE4}\u{10AEF}\u{10B81}\u{10B83}-\u{10B85}\u{10B89}\u{10B8C}\u{10B8E}-\u{10B8F}\u{10B91}\u{10BA9}-\u{10BAC}\u{10D22}\u{10EC2}\u{10F33}\u{10F54}\u{10F74}-\u{10F75}\u{10FB4}-\u{10FB6}\u{10FB9}-\u{10FBA}\u{10FBD}\u{10FC2}-\u{10FC3}\u{10FC9}]'
      # https://datatracker.ietf.org/doc/html/rfc5892#appendix-A.1
      # https://datatracker.ietf.org/doc/html/rfc5892#appendix-A.2
      ZERO_WIDTH_VIRAMA = "#{VIRAMA_CHARACTER_CLASS}[\\u{200C}\\u{200D}]"
      ZERO_WIDTH_NON_JOINER_JOINING_TYPE = "[#{JOINING_TYPE_L_CHARACTER_CLASS}#{JOINING_TYPE_D_CHARACTER_CLASS}]#{JOINING_TYPE_T_CHARACTER_CLASS}*\\u{200C}#{JOINING_TYPE_T_CHARACTER_CLASS}*[#{JOINING_TYPE_R_CHARACTER_CLASS}#{JOINING_TYPE_D_CHARACTER_CLASS}]"
      # https://datatracker.ietf.org/doc/html/rfc5892#appendix-A.3
      MIDDLE_DOT = '\u{006C}\u{00B7}\u{006C}'
      # https://datatracker.ietf.org/doc/html/rfc5892#appendix-A.4
      GREEK_LOWER_NUMERAL_SIGN = '\u{0375}\p{Greek}'
      # https://datatracker.ietf.org/doc/html/rfc5892#appendix-A.5
      # https://datatracker.ietf.org/doc/html/rfc5892#appendix-A.6
      HEBREW_PUNCTUATION = '\p{Hebrew}[\u{05F3}\u{05F4}]'
      CONTEXT_REGEX = /(#{ZERO_WIDTH_VIRAMA}|#{ZERO_WIDTH_NON_JOINER_JOINING_TYPE}|#{MIDDLE_DOT}|#{GREEK_LOWER_NUMERAL_SIGN}|#{HEBREW_PUNCTUATION})/.freeze
      # https://datatracker.ietf.org/doc/html/rfc5892#appendix-A.7
      KATAKANA_MIDDLE_DOT_REGEX = /\u{30FB}/.freeze
      KATAKANA_MIDDLE_DOT_CONTEXT_REGEX = /[\p{Hiragana}\p{Katakana}\p{Han}]/.freeze
      # https://datatracker.ietf.org/doc/html/rfc5892#appendix-A.8
      # https://datatracker.ietf.org/doc/html/rfc5892#appendix-A.9
      ARABIC_INDIC_DIGITS_REGEX = /[\u{0660}-\u{0669}]/.freeze
      ARABIC_EXTENDED_DIGITS_REGEX = /[\u{06F0}-\u{06F9}]/.freeze

      MAX_A_LABEL_SIZE = 63
      MAX_HOSTNAME_SIZE = 253

      def valid_hostname?(data)
        hostname_size = 0
        data.split(LABEL_SEPARATOR_REGEX, -1).map do |label|
          a_label = SimpleIDN.to_ascii(label)
          return false if a_label.size > MAX_A_LABEL_SIZE
          hostname_size += a_label.size + 1 # include separator
          return false if hostname_size > MAX_HOSTNAME_SIZE
          u_label = SimpleIDN.to_unicode(a_label)
          # https://datatracker.ietf.org/doc/html/rfc5891#section-4.2.3.1
          return false if u_label.slice(2, 2) == '--'
          return false if ARABIC_INDIC_DIGITS_REGEX.match?(u_label) && ARABIC_EXTENDED_DIGITS_REGEX.match?(u_label)
          u_label.gsub!(CONTEXT_REGEX, 'ok')
          u_label.gsub!(KATAKANA_MIDDLE_DOT_REGEX, 'ok') if KATAKANA_MIDDLE_DOT_CONTEXT_REGEX.match?(u_label)
          u_label
        end.join('.').match?(HOSTNAME_REGEX)
      rescue SimpleIDN::ConversionError
        false
      end
    end
  end
end
