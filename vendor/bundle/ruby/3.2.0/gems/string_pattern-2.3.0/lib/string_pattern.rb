SP_ADD_TO_RUBY = true if !defined?(SP_ADD_TO_RUBY)
require_relative "string/pattern/add_to_ruby" if SP_ADD_TO_RUBY
require_relative "string/pattern/analyze"
require_relative "string/pattern/generate"
require_relative "string/pattern/validate"

# SP_ADD_TO_RUBY: (TrueFalse, default: true) You need to add this constant value before requiring the library if you want to modify the default.
#               If true it will add 'generate' and 'validate' methods to the classes: Array, String and Symbol. Also it will add 'generate' method to Kernel
#               aliases: 'gen' for 'generate' and 'val' for 'validate'
#               Examples of use:
#                 "(,3:N,) ,3:N,-,2:N,-,2:N".split(",").generate #>(937) 980-65-05
#                 %w{( 3:N ) 1:_ 3:N - 2:N - 2:N}.gen #>(045) 448-63-09
#                 ["1:L", "5-10:LN", "-", "3:N"].gen #>zqWihV-746
#                 gen("10:N") #>3433409877
#                 "20-30:@".gen #>dkj34MljjJD-df@jfdluul.dfu
#                 "10:L/N/[/-./%d%]".validate("12ds6f--.s") #>[:value, :string_set_not_allowed]
#                 "20-40:@".validate(my_email)
# national_chars: (Array, default: english alphabet)
#                 Set of characters that will be used when using T pattern
# optimistic: (TrueFalse, default: true)
#             If true it will check on the strings of the array positions if they have the pattern format and assume in that case that is a pattern.
# dont_repeat: (TrueFalse, default: false)
#             If you want to generate for example 1000 strings and be sure all those strings are different you can set it to true
# default_infinite: (Integer, default: 10)
#             In case using regular expressions the maximum when using * or + for repetitions
# word_separator: (String, default: '_')
#             When generating words using symbol types 'w' or 'p' the character to separate the english or spanish words.
# block_list: (Array, default: empty)
#             Array of words to be avoided from resultant strings.
# block_list_enabled: (TrueFalse, default: false)
#             If true block_list will be take in consideration
class StringPattern
  class << self
    attr_accessor :national_chars, :optimistic, :dont_repeat, :cache, :cache_values, :default_infinite, :word_separator, :block_list, :block_list_enabled
  end
  @national_chars = (("a".."z").to_a + ("A".."Z").to_a).join
  @optimistic = true
  @cache = Hash.new()
  @cache_values = Hash.new()
  @dont_repeat = false
  @default_infinite = 10
  @word_separator = "_"
  @block_list_enabled = false
  @block_list = []
  NUMBER_SET = ("0".."9").to_a
  SPECIAL_SET = [" ", "~", "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "-", "_", "+", "=", "{", "}", "[", "]", "'", ";", ":", "?", ">", "<", "`", "|", "/", '"']
  ALPHA_SET_LOWER = ("a".."z").to_a
  ALPHA_SET_CAPITAL = ("A".."Z").to_a
  @palabras = []
  @palabras_camel = []
  @words = []
  @words_camel = []
  @palabras_short = []
  @words_short = []
  @palabras_camel_short = []
  @words_camel_short = []

  Pattern = Struct.new(:min_length, :max_length, :symbol_type, :required_data, :excluded_data, :data_provided,
                       :string_set, :all_characters_set, :unique)

  def self.national_chars=(par)
    @cache = Hash.new()
    @national_chars = par
  end

end
