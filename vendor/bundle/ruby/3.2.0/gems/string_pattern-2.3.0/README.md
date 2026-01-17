# StringPattern

[![Gem Version](https://badge.fury.io/rb/string_pattern.svg)](https://rubygems.org/gems/string_pattern)
[![Build Status](https://travis-ci.com/MarioRuiz/string_pattern.svg?branch=master)](https://github.com/MarioRuiz/string_pattern)
[![Coverage Status](https://coveralls.io/repos/github/MarioRuiz/string_pattern/badge.svg?branch=master)](https://coveralls.io/github/MarioRuiz/string_pattern?branch=master)

With this gem, you can easily generate strings supplying a very simple pattern. Even generate random words in English or Spanish.
Also, you can validate if a text fulfills a specific pattern or even generate a string following a pattern and returning the wrong length, value... for testing your applications. Perfect to be used in test data factories.

Also you can use regular expressions (Regexp) to generate strings: `/[a-z0-9]{2,5}\w+/.gen`

To do even more take a look at [nice_hash gem](https://github.com/MarioRuiz/nice_hash)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'string_pattern'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install string_pattern

## Usage

### What is a string pattern?

A pattern is a string where we supply these elements "a-b:c" where a is min_length, b is max_length (optional) and c is a set of symbol_type

    min_length: minimum length of the string
	
    max_length (optional): maximum length of the string. If not provided, the result will be with the min_length provided
    
	symbol_type: The type of the string we want.
        x: from a to z (lowercase)
        X: A to Z (capital letters)
        L: A to Z and a to z
        T: National characters defined on StringPattern.national_chars
        n or N: for numbers. 0 to 9
        $: special characters, $%&#...  (includes blank space)
        _: blank space
        *: all characters
        0: empty string will be accepted.  It needs to be at the beginning of the symbol_type string
            @: It will generate a valid email following the official algorithm. It cannot be used with other symbol_type
            W: for English words, capital and lower. It cannot be used with other symbol_type
            w: for English words only lower and words separated by underscore. It cannot be used with other symbol_type
            P: for Spanish words, capital and lower. It cannot be used with other symbol_type
            p: for Spanish words only lower and words separated by underscore. It cannot be used with other symbol_type
		
### How to generate a string following a pattern

To generate a string following a pattern you can do it using directly the StringPattern class or the generate method in the class, be aware you can always use also the alias method: gen

```ruby
require 'string_pattern'

#StringPattern class
p StringPattern.generate "10:N"
#>3448910834
p StringPattern.gen "5:X"
#>JDDDK

#String class
p "4:Nx".gen
#>xaa3

#Symbol class
p :"10:T".generate
#>AccBdjklñD

#Array class
p [:"3:N", "fixed", :"3:N"].gen
#>334fixed920
p "(,3:N,) ,3:N,-,2:N,-,2:N".split(',').generate 
#>(937) 980-65-05

#Kernel
p gen "3:N"
#>443
```

#### Generating unique strings

If you want to generate for example 1000 strings and be sure all those strings are different you can use:

```ruby
StringPattern.dont_repeat = true #default: false
1000.times {
	puts :"6-20:L/N/".gen
}
StringPattern.cache_values = Hash.new() #to clean the generated values from memory
```

Using dont_repeat all the generated string during the current run will be unique.

In case you just want one particular string to be unique but not the rest then add to the pattern just in the end the symbol: &

The pattern needs to be a symbol object.

```ruby
1000.times {
	puts :"6-20:L/N/&".gen #will be unique
	puts :"10:N".gen
}
```

#### Generate words randomly in English or Spanish

To generate a string of the length you want that will include only real words, use the symbol types:
* W: generates English words following CamelCase ('ExampleOutput')
* w: generates English words following snake_case ('example_output')
* P: generates Spanish words following CamelCase ('EjemploSalida')
* p: generates Spanish words following snake_case ('ejemplo_salida')

```ruby
require 'string_pattern'

puts '10-30:W'.gen
#> FirstLieutenant
puts '10-30:w'.gen
#> paris_university
puts '10-30:P'.gen
#> SillaMetalizada
puts '10-30:p'.gen
#> despacho_grande
```

If you want to use a different word separator than "_" when using 'w' or 'p':

```ruby
# blank space for example
require 'string_pattern'

StringPattern.word_separator = ' '

puts '10-30:w'.gen
#> paris university
puts '10-30:p'.gen
#> despacho grande
```

The word list is loaded on the first request to generate words, after that the speed to generate words increases amazingly. 85000 English words and 250000 Spanish words. The vocabularies are a sample of public open sources.

#### Generate strings using Regular Expressions (Regexp)

Take in consideration this feature is not supporting all possibilities for Regular expressions but it is fully functional. If you find any bug or limitation please add it to issues: https://github.com/MarioRuiz/string_pattern/issues

In case you want to change the default maximum for repetitions when using * or +: `StringPattern.default_infinite = 30` . By default is 10.

If you want to translate a regular expression into an StringPattern use the method we added to Regexp class: `to_sp`

Examples:

```ruby
/[a-z0-9]{2-5}\w+/.to_sp
#> ["2-5:nx", "1-10:Ln_"]

#regular expression for UUID v4
/[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}/.to_sp
#> ["8:n[ABCDEF]", "-", "4:n[ABCDEF]", "-4", "3:n[ABCDEF]", "-", "1:[89AB]", "3:n[ABCDEF]", "-", "12:n[ABCDEF]"]
```

If you want to generate a random string following the regular expression, you can do it like a normal string pattern:

```ruby

regexp = /[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}/

# using StringPattern class
puts StringPattern.generate(regexp)

# using Kernel
puts generate(regexp)

# using generate method added to Regexp class
puts regexp.generate

#using the alias 'gen'
puts regexp.gen 

# output:
#>7009574B-6F2F-436E-BB7A-EA5FDA6B4E47
#>5FB1718F-108A-4F62-8170-33C43FD86B1D
#>05745B6F-93BA-475F-8118-DD56E5EAC4D1
#>2D6FC189-8D50-45A8-B182-780193838502

```

### String patterns

#### How to generate one or another string

In case you need to specify that the string is generated selecting one or another fixed string or pattern, you can do it by using Array of patterns and in the position you want you can add an array with the possible values

```ruby
p ["uno:", :"5:N", ['.red','.green', :'3:L'] ].gen

# first position a fixed string: "uno:"
# second position 5 random numbers
# third position one of these values: '.red', '.green' or 3 letters

# example output: 
# 'uno:34322.red'
# 'uno:44432.green'
# 'uno:34322.red'
# 'uno:28795xAB'

```

Take in consideration that this is only available to generate successful strings but not for validation

#### Custom characters

Also, it's possible to provide the characters we want. To do that we'll use the symbol_type [characters]

If we want to add the character ] we have to write ]]

Examples

```ruby
# four chars from the ones provided: asDF9
p "4:[asDF9]".gen    #> aaaa, asFF, 9sFD

# from 2 to 20 chars, capital and lower chars (Xx) and also valid the characters $#6
p "2-20:[$#6]Xx".gen    #> aaaa, asFF, 66, B$DkKL#9aDD
 
# four chars from these: asDF]9
p "4:[asDF]]9]".gen    #> aa]a, asFF, 9s]D
```

#### Required characters or symbol types

We'll use the symbol / to specify which characters or symbols we want to be included on the resulting string as required values /symbols or characters/

If we need to add the character / we'll use //

Examples:

```ruby
# four characters. optional: capitals and numbers, required: lower
"4:XN/x/".gen    # aaaa, FF9b, j4em, asdf, ADFt

# from 6 to 15 chars. optional: numbers, capitals and the chars $ and Æ. required the chars: 23abCD
"6-15:[/23abCD/$Æ]NX".gen    # bCa$D32, 32DJIOKLaCb, b23aD568C
 
# from 4 to 9 chars. optional: numbers and capitals. required: lowers and the characters $ and 5
"4-9:[/$5/]XN/x/".generate    # aa5$, F5$F9b, j$4em5, a5sdf$, $ADFt5 
```

#### Excluded characters

If we want to exclude a few characters in the result, we'll use the symbol %characters%

If you need to exclude the character %, you should use %%

Examples: 

```ruby
# from 2 to 20 characters. optional: Numbers and characters A, B and C. excluded: the characters 8 and 3
"2-20:[%83%ABC]N".gen    # B49, 22900, 9CAB, 22, 11CB6270C26C4572A50C

# 10 chars. optional: Letters (capital and lower). required: numbers. excluded: the characters 0 and WXYzZ
"10:L/n/[%0WXYzZ%]".gen    # GoO2ukCt4l, Q1Je2remFL, qPg1T92T2H, 4445556781
```

#### Not fulfilling a pattern

If we want our resulting string doesn't fulfill the pattern we supply, then we'll use the symbol ! at the beginning

Examples:

```ruby
"!4:XN/x/".gen    # a$aaa, FF9B, j4DDDem, as, 2345

"!10:N".gen     # 123, 34899Add34, 3434234234234008, AAFj#kd2x
```

### Generate a string with specific expected errors

Usually, for testing purposes you need to generate strings that don't fulfill a specific pattern, then you can supply as a parameter expected_errors (alias: errors)

The possible values you can specify is one or more of these ones: :length, :min_length, :max_length, :value, :required_data, :excluded_data, :string_set_not_allowed

    :length: wrong length, minimum or maximum
    :min_length: wrong minimum length
    :max_length: wrong maximum length
    :value: wrong resultant value
    :required_data: the output string won't include all necessary required data. It works only if required data supplied on the pattern.
    :excluded_data: the resultant string will include one or more characters that should be excluded. It works only if excluded data supplied on the pattern.
    :string_set_not_allowed: it will include one or more characters that are not supposed to be on the string.
  
Examples:

```ruby
"10-20:N".gen errors: [:min_length]
#> 627, 098262, 3408

"20:N".gen errors: [:length, :value]
#> |13, tS1b)r-1)<RT65202eTo6bV0g~, 021400323<2ahL0NP86a698063*56076

"10:L/n/".gen errors: [:value]
#> 1hwIw;v{KQ, mpk*l]!7:!, wocipgZt8@

```

### Validate if a string is following a pattern

If you need to validate if a specific text is fulfilling the pattern you can use the validate method.

If a string pattern supplied and no other parameters supplied the output will be an array with the errors detected. 


Possible output values, empty array (validation without errors detected) or one or more of: :min_length, :max_length, :length, :value, :string_set_not_allowed, :required_data, :excluded_data

In case an array of patterns supplied it will return only true or false

Examples:

```ruby
#StringPattern class
StringPattern.validate((text: "This text will be validated", pattern: :"10-20:Xn")
#> [:max_length, :length, :value, :string_set_not_allowed]

#String class
"10:N".validate "333444"
#> [:min_length, :length]

#Symbol class
:"10:N".validate("333444")
#> [:min_length, :length]

#Array class
["5:L","3:xn","4-10:n"].validate "DjkljFFc343444390"
#> false
```

If we want to validate a string with a pattern and we are expecting to get specific errors, you can supply the parameter expected_errors (alias: errors) or not_expected_errors (aliases: non_expected_errors, not_errors).

In this case, the validate method will return true or false.

Examples: 

```ruby
"10:N".val "3445", errors: [:min_length]
#> true

"10:N/[09]/".validate "4434039440", errors: [:value]
#> false

"10-12:XN/x/".validate "FDDDDDAA343434", errors: [:max_length, :required_data]
#> true
```

### Configure

#### SP_ADD_TO_RUBY

This gem adds the methods generate (alias: gen) and validate (alias: val) to the Ruby classes: String, Array, and Symbol. 

Also adds the method generate (alias: gen) to Kernel. By default (true) it is always added. 

In case you don't want to be added, just before requiring the library set:

```ruby
SP_ADD_TO_RUBY = false
require 'string_pattern'
```

In case it is set to true (default) then you will be able to use:

```ruby
require 'string_pattern'

#String object
"20-30:@".gen 
#>dkj34MljjJD-df@jfdluul.dfu

"10:L/N/[/-./%d%]".validate("12ds6f--.s") 
#>[:value, :string_set_not_allowed]

"20-40:@".validate(my_email)

#Kernel
gen "10:N"
#>3433409877

#Array object
"(,3:N,) ,3:N,-,2:N,-,2:N".split(",").generate 
#>(937) 980-65-05

%w{( 3:N ) 1:_ 3:N - 2:N - 2:N}.gen 
#>(045) 448-63-09

["1:L", "5-10:LN", "-", "3:N"].gen 
#>zqWihV-746
```

#### national_chars

To specify which national characters will be used when using the symbol type: T, you use StringPattern.national_chars, by default is the English alphabet

```ruby
StringPattern.national_chars = (('a'..'z').to_a + ('A'..'Z').to_a).join + "áéíóúÁÉÍÓÚüÜñÑ"
"10-20:Tn".gen #>AAñ34Ef99éNOP
```

#### optimistic

If true it will check on the strings of the array positions supplied if they have the pattern format and assume in that case that is a pattern. If not it will assume the patterns on the array will be supplied as symbols. By default is set to true.

```ruby
StringPattern.optimistic = false
["5:X","fixedtext", "3:N"].generate
#>5:Xfixedtext3:N
[:"5:X","fixedtext", :"3:N"].generate
#>AUJKJfixedtext454

StringPattern.optimistic = true
["5:X","fixedtext", "3:N"].generate
#>KKDMEfixedtext344
[:"5:X","fixedtext", :"3:N"].generate
#>SAAERfixedtext988
```

#### block_list

To specify which words will be avoided from the results

```ruby
StringPattern.block_list = ['example', 'wrong', 'ugly']
StringPattern.block_list_enabled = true
"2-20:Tn".gen #>AAñ34Ef99éNOP
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/marioruiz/string_pattern.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

