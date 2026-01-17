# JsonPath

This is an implementation of http://goessner.net/articles/JsonPath/.

## What is JsonPath?

JsonPath is a way of addressing elements within a JSON object. Similar to xpath
of yore, JsonPath lets you traverse a json object and manipulate or access it.

## Usage

### Command-line

There is stand-alone usage through the binary `jsonpath`

    jsonpath [expression] (file|string)

    If you omit the second argument, it will read stdin, assuming one valid JSON
    object per line. Expression must be a valid jsonpath expression.

### Library

To use JsonPath as a library simply include and get goin'!

```ruby
require 'jsonpath'

json = <<-HERE_DOC
{"store":
  {"bicycle":
    {"price":19.95, "color":"red"},
    "book":[
      {"price":8.95, "category":"reference", "title":"Sayings of the Century", "author":"Nigel Rees"},
      {"price":12.99, "category":"fiction", "title":"Sword of Honour", "author":"Evelyn Waugh"},
      {"price":8.99, "category":"fiction", "isbn":"0-553-21311-3", "title":"Moby Dick", "author":"Herman Melville","color":"blue"},
      {"price":22.99, "category":"fiction", "isbn":"0-395-19395-8", "title":"The Lord of the Rings", "author":"Tolkien"}
    ]
  }
}
HERE_DOC
```

Now that we have a JSON object, let's get all the prices present in the object.
We create an object for the path in the following way.

```ruby
path = JsonPath.new('$..price')
```

Now that we have a path, let's apply it to the object above.

```ruby
path.on(json)
# => [19.95, 8.95, 12.99, 8.99, 22.99]
```

Or reuse it later on some other object (thread safe) ...

```ruby
path.on('{"books":[{"title":"A Tale of Two Somethings","price":18.88}]}')
# => [18.88]
```

You can also just combine this into one mega-call with the convenient
`JsonPath.on` method.

```ruby
JsonPath.on(json, '$..author')
# => ["Nigel Rees", "Evelyn Waugh", "Herman Melville", "Tolkien"]
```

Of course the full JsonPath syntax is supported, such as array slices

```ruby
JsonPath.new('$..book[::2]').on(json)
# => [
#      {"price" => 8.95, "category" => "reference", "title" => "Sayings of the Century", "author" => "Nigel Rees"},
#      {"price" => 8.99, "category" => "fiction", "isbn" => "0-553-21311-3", "title" => "Moby Dick", "author" => "Herman Melville","color" => "blue"},
#    ]
```

...and evals, including those with conditional operators

```ruby
JsonPath.new("$..price[?(@ < 10)]").on(json)
# => [8.95, 8.99]

JsonPath.new("$..book[?(@['price'] == 8.95 || @['price'] == 8.99)].title").on(json)
# => ["Sayings of the Century", "Moby Dick"]

JsonPath.new("$..book[?(@['price'] == 8.95 && @['price'] == 8.99)].title").on(json)
# => []
```

There is a convenience method, `#first` that gives you the first element for a
JSON object and path.

```ruby
JsonPath.new('$..color').first(json)
# => "red"
```

As well, we can directly create an `Enumerable` at any time using `#[]`. 

```ruby
enum = JsonPath.new('$..color')[json]
# => #<JsonPath::Enumerable:...>
enum.first
# => "red"
enum.any?{ |c| c == 'red' }
# => true
```

For more usage examples and variations on paths, please visit the tests. There
are some more complex ones as well.

### Querying ruby data structures

If you have ruby hashes with symbolized keys as input, you
can use `:use_symbols` to make JsonPath work fine on them too:

```ruby
book = { title: "Sayings of the Century" }

JsonPath.new('$.title').on(book)
# => []

JsonPath.new('$.title', use_symbols: true).on(book)
# => ["Sayings of the Century"]
```

JsonPath also recognizes objects responding to `dig` (introduced
in ruby 2.3), and therefore works out of the box with Struct,
OpenStruct, and other Hash-like structures:

```ruby
book_class = Struct.new(:title)
book = book_class.new("Sayings of the Century")

JsonPath.new('$.title').on(book)
# => ["Sayings of the Century"]
```

JsonPath is able to query pure ruby objects and uses `__send__`
on them. The option is enabled by default in JsonPath 1.x, but
we encourage to enable it explicitly:

```ruby
book_class = Class.new{ attr_accessor :title }
book = book_class.new
book.title = "Sayings of the Century"

JsonPath.new('$.title', allow_send: true).on(book)
# => ["Sayings of the Century"]
```

### Other available options

By default, JsonPath does not return null values on unexisting paths.
This can be changed using the `:default_path_leaf_to_null` option

```ruby
JsonPath.new('$..book[*].isbn').on(json)
# => ["0-553-21311-3", "0-395-19395-8"]

JsonPath.new('$..book[*].isbn', default_path_leaf_to_null: true).on(json)
# => [nil, nil, "0-553-21311-3", "0-395-19395-8"]
```

When JsonPath returns a Hash, you can ask to symbolize its keys
using the `:symbolize_keys` option

```ruby
JsonPath.new('$..book[0]').on(json)
# => [{"category" => "reference", ...}]

JsonPath.new('$..book[0]', symbolize_keys: true).on(json)
# => [{category: "reference", ...}]
```

### Selecting Values

It's possible to select results once a query has been defined after the query. For
example given this JSON data:

```bash
{
    "store": {
        "book": [
            {
                "category": "reference",
                "author": "Nigel Rees",
                "title": "Sayings of the Century",
                "price": 8.95
            },
            {
                "category": "fiction",
                "author": "Evelyn Waugh",
                "title": "Sword of Honour",
                "price": 12.99
            }
        ]
}
```

... and this query:

```ruby
"$.store.book[*](category,author)"
```

... the result can be filtered as such:

```bash
[
   {
      "category" : "reference",
      "author" : "Nigel Rees"
   },
   {
      "category" : "fiction",
      "author" : "Evelyn Waugh"
   }
]
```

### Manipulation

If you'd like to do substitution in a json object, you can use `#gsub`
or `#gsub!` to modify the object in place.

```ruby
JsonPath.for('{"candy":"lollipop"}').gsub('$..candy') {|v| "big turks" }.to_hash
```

The result will be

```ruby
{'candy' => 'big turks'}
```

If you'd like to remove all nil keys, you can use `#compact` and `#compact!`.
To remove all keys under a certain path, use `#delete` or `#delete!`. You can
even chain these methods together as follows:

```ruby
json = '{"candy":"lollipop","noncandy":null,"other":"things"}'
o = JsonPath.for(json).
  gsub('$..candy') {|v| "big turks" }.
  compact.
  delete('$..other').
  to_hash
# => {"candy" => "big turks"}
```

### Fetch all paths

To fetch all possible paths in given json, you can use `fetch_all_path`` method.

data:

```bash
{
    "store": {
        "book": [
            {
                "category": "reference",
                "author": "Nigel Rees"
            },
            {
                "category": "fiction",
                "author": "Evelyn Waugh"
            }
        ]
}
```

... and this query:

```ruby
JsonPath.fetch_all_path(data)
```

... the result will be:

```bash
["$", "$.store", "$.store.book", "$.store.book[0].category", "$.store.book[0].author", "$.store.book[0]", "$.store.book[1].category", "$.store.book[1].author", "$.store.book[1]"]
```



# Contributions

Please feel free to submit an Issue or a Pull Request any time you feel like
you would like to contribute. Thank you!

## Running an individual test

```ruby
ruby -Ilib:../lib test/test_jsonpath.rb --name test_wildcard_on_intermediary_element_v6
```
