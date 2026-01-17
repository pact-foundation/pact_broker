# frozen_string_literal: true

require 'minitest/autorun'
require 'phocus'
require 'jsonpath'
require 'json'

class TestJsonpathReadme < MiniTest::Unit::TestCase

  def setup
    @json = <<-HERE_DOC
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
  end
  attr_reader :json

  def test_library_section
    path = JsonPath.new('$..price')
    assert_equal [19.95, 8.95, 12.99, 8.99, 22.99], path.on(json)
    assert_equal [18.88], path.on('{"books":[{"title":"A Tale of Two Somethings","price":18.88}]}')
    assert_equal ["Nigel Rees", "Evelyn Waugh", "Herman Melville", "Tolkien"], JsonPath.on(json, '$..author')
    assert_equal [
      {"price" => 8.95, "category" => "reference", "title" => "Sayings of the Century", "author" => "Nigel Rees"},
      {"price" => 8.99, "category" => "fiction", "isbn" => "0-553-21311-3", "title" => "Moby Dick", "author" => "Herman Melville","color" => "blue"},
    ], JsonPath.new('$..book[::2]').on(json)
    assert_equal [8.95, 8.99], JsonPath.new("$..price[?(@ < 10)]").on(json)
    assert_equal ["Sayings of the Century", "Moby Dick"], JsonPath.new("$..book[?(@['price'] == 8.95 || @['price'] == 8.99)].title").on(json)
    assert_equal [], JsonPath.new("$..book[?(@['price'] == 8.95 && @['price'] == 8.99)].title").on(json)
    assert_equal "red", JsonPath.new('$..color').first(json)
  end

  def test_library_section_enumerable
    enum = JsonPath.new('$..color')[json]
    assert_equal "red", enum.first
    assert enum.any?{ |c| c == 'red' }
  end

  def test_ruby_structures_section
    book = { title: "Sayings of the Century" }
    assert_equal [], JsonPath.new('$.title').on(book)
    assert_equal ["Sayings of the Century"], JsonPath.new('$.title', use_symbols: true).on(book)

    book_class = Struct.new(:title)
    book = book_class.new("Sayings of the Century")
    assert_equal ["Sayings of the Century"], JsonPath.new('$.title').on(book)

    book_class = Class.new{ attr_accessor :title }
    book = book_class.new
    book.title = "Sayings of the Century"
    assert_equal ["Sayings of the Century"], JsonPath.new('$.title', allow_send: true).on(book)
  end

  def test_options_section
    assert_equal ["0-553-21311-3", "0-395-19395-8"], JsonPath.new('$..book[*].isbn').on(json)
    assert_equal [nil, nil, "0-553-21311-3", "0-395-19395-8"], JsonPath.new('$..book[*].isbn', default_path_leaf_to_null: true).on(json)

    assert_equal ["price", "category", "title", "author"], JsonPath.new('$..book[0]').on(json).map(&:keys).flatten.uniq
    assert_equal [:price, :category, :title, :author], JsonPath.new('$..book[0]').on(json, symbolize_keys: true).map(&:keys).flatten.uniq
  end

  def selecting_value_section
    json = <<-HERE_DOC
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
    HERE_DOC
    got = JsonPath.on(json, "$.store.book[*](category,author)")
    expected = [
       {
          "category" => "reference",
          "author" => "Nigel Rees"
       },
       {
          "category" => "fiction",
          "author" => "Evelyn Waugh"
       }
    ]
    assert_equal expected, got
  end

  def test_manipulation_section
    assert_equal({"candy" => "big turks"}, JsonPath.for('{"candy":"lollipop"}').gsub('$..candy') {|v| "big turks" }.to_hash)

    json = '{"candy":"lollipop","noncandy":null,"other":"things"}'
    o = JsonPath.for(json).
      gsub('$..candy') {|v| "big turks" }.
      compact.
      delete('$..other').
      to_hash
    assert_equal({"candy" => "big turks"}, o)
  end

end
