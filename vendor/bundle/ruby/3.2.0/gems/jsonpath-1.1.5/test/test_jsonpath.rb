# frozen_string_literal: true

require 'minitest/autorun'
require 'phocus'
require 'jsonpath'
require 'json'

class TestJsonpath < MiniTest::Unit::TestCase
  def setup
    @object = example_object
    @object2 = example_object
  end

  def test_bracket_matching
    assert_raises(ArgumentError) { JsonPath.new('$.store.book[0') }
    assert_raises(ArgumentError) { JsonPath.new('$.store.book[0]]') }
    assert_equal [9], JsonPath.new('$.store.book[0].price').on(@object)
  end

  def test_lookup_direct_path
    assert_equal 7, JsonPath.new('$.store.*').on(@object).first['book'].size
  end

  def test_lookup_missing_element
    assert_equal [], JsonPath.new('$.store.book[99].price').on(@object)
  end

  def test_retrieve_all_authors
    assert_equal [
      @object['store']['book'][0]['author'],
      @object['store']['book'][1]['author'],
      @object['store']['book'][2]['author'],
      @object['store']['book'][3]['author'],
      @object['store']['book'][4]['author'],
      @object['store']['book'][5]['author'],
      @object['store']['book'][6]['author']
    ], JsonPath.new('$..author').on(@object)
  end

  def test_retrieve_all_prices
    assert_equal [
      @object['store']['bicycle']['price'],
      @object['store']['book'][0]['price'],
      @object['store']['book'][1]['price'],
      @object['store']['book'][2]['price'],
      @object['store']['book'][3]['price']
    ].sort, JsonPath.new('$..price').on(@object).sort
  end

  def test_recognize_array_splices
    assert_equal [@object['store']['book'][0]], JsonPath.new('$..book[0:1:1]').on(@object)
    assert_equal [@object['store']['book'][0], @object['store']['book'][1]], JsonPath.new('$..book[0:2:1]').on(@object)
    assert_equal [@object['store']['book'][1], @object['store']['book'][3], @object['store']['book'][5]], JsonPath.new('$..book[1::2]').on(@object)
    assert_equal [@object['store']['book'][0], @object['store']['book'][2], @object['store']['book'][4], @object['store']['book'][6]], JsonPath.new('$..book[::2]').on(@object)
    assert_equal [@object['store']['book'][0], @object['store']['book'][2]], JsonPath.new('$..book[:-5:2]').on(@object)
    assert_equal [@object['store']['book'][5], @object['store']['book'][6]], JsonPath.new('$..book[5::]').on(@object)
  end

  def test_slice_array_with_exclusive_end_correctly
    assert_equal [@object['store']['book'][0], @object['store']['book'][1]], JsonPath.new('$..book[:2]').on(@object)
  end

  def test_recognize_array_comma
    assert_equal [@object['store']['book'][0], @object['store']['book'][1]], JsonPath.new('$..book[0,1]').on(@object)
    assert_equal [@object['store']['book'][2], @object['store']['book'][6]], JsonPath.new('$..book[2,-1::]').on(@object)
  end

  def test_recognize_filters
    assert_equal [@object['store']['book'][2], @object['store']['book'][3]], JsonPath.new("$..book[?(@['isbn'])]").on(@object)
    assert_equal [@object['store']['book'][0], @object['store']['book'][2]], JsonPath.new("$..book[?(@['price'] < 10)]").on(@object)
    assert_equal [@object['store']['book'][0], @object['store']['book'][2]], JsonPath.new("$..book[?(@['price'] == 9)]").on(@object)
    assert_equal [@object['store']['book'][3]], JsonPath.new("$..book[?(@['price'] > 20)]").on(@object)
  end

  def test_not_equals_operator
    expected =
      [
        @object['store']['book'][0],
        @object['store']['book'][4],
        @object['store']['book'][5],
        @object['store']['book'][6]
      ]
    assert_equal(expected, JsonPath.new("$..book[?(@['category'] != 'fiction')]").on(@object))
    assert_equal(expected, JsonPath.new("$..book[?(@['category']!=fiction)]").on(@object))
    assert_equal(expected, JsonPath.new("$..book[?(@.category!=fiction)]").on(@object))
    assert_equal(expected, JsonPath.new("$..book[?(@.category != 'fiction')]").on(@object))
  end

  def test_or_operator
    assert_equal [@object['store']['book'][1], @object['store']['book'][3]], JsonPath.new("$..book[?(@['price'] == 13 || @['price'] == 23)]").on(@object)
    result = ["Sayings of the Century", "Sword of Honour", "Moby Dick", "The Lord of the Rings"]
    assert_equal result, JsonPath.new("$..book[?(@.price==13 || @.price==9 || @.price==23)].title").on(@object)
    assert_equal result, JsonPath.new("$..book[?(@.price==9 || @.price==23 || @.price==13)].title").on(@object)
    assert_equal result, JsonPath.new("$..book[?(@.price==23 || @.price==13 || @.price==9)].title").on(@object)
  end

  def test_or_operator_with_not_equals
    # Should be the same regardless of key style ( @.key vs @['key'] )
    result = ['Nigel Rees', 'Evelyn Waugh', 'Herman Melville', 'J. R. R. Tolkien', 'Lukyanenko']
    assert_equal result, JsonPath.new("$..book[?(@['title']=='Osennie Vizity' || @['author']!='Lukyanenko')].author").on(@object)
    assert_equal result, JsonPath.new("$..book[?(@.title=='Osennie Vizity' || @.author != Lukyanenko )].author").on(@object)
    assert_equal result, JsonPath.new("$..book[?(@.title=='Osennie Vizity' || @.author!=Lukyanenko )].author").on(@object)
  end

  def test_and_operator
    assert_equal [], JsonPath.new("$..book[?(@['price'] == 13 && @['price'] == 23)]").on(@object)
    assert_equal [], JsonPath.new("$..book[?(@.price>=13 && @.category==fiction && @.title==no_match)]").on(@object)
    assert_equal [], JsonPath.new("$..book[?(@.title==no_match && @.category==fiction && @.price==13)]").on(@object)
    assert_equal [], JsonPath.new("$..book[?(@.price==13 && @.title==no_match && @.category==fiction)]").on(@object)
    assert_equal [], JsonPath.new("$..book[?(@.price==13 && @.bad_key_name==true && @.category==fiction)]").on(@object)

    expected = [@object['store']['book'][1]]
    assert_equal expected, JsonPath.new("$..book[?(@['price'] < 23 && @['price'] > 9)]").on(@object)
    assert_equal expected, JsonPath.new("$..book[?(@.price < 23 && @.price > 9)]").on(@object)

    expected = ['Sword of Honour', 'The Lord of the Rings']
    assert_equal expected, JsonPath.new("$..book[?(@.price>=13 && @.category==fiction)].title").on(@object)
    assert_equal ['The Lord of the Rings'], JsonPath.new("$..book[?(@.category==fiction && @.isbn && @.price>9)].title").on(@object)
    assert_equal ['Sayings of the Century'], JsonPath.new("$..book[?(@['price'] == 9 && @.author=='Nigel Rees')].title").on(@object)
    assert_equal ['Sayings of the Century'], JsonPath.new("$..book[?(@['price'] == 9 && @.tags..asdf)].title").on(@object)
  end

  def test_and_operator_with_not_equals
    expected = ['Nigel Rees']
    assert_equal expected, JsonPath.new("$..book[?(@['price']==9 && @['category']!=fiction)].author").on(@object)
    assert_equal expected, JsonPath.new("$..book[?(@.price==9 && @.category!=fiction)].author").on(@object)
  end

  def test_nested_grouping
    path = "$..book[?((@['price'] == 19 && @['author'] == 'Herman Melville') || @['price'] == 23)]"
    assert_equal [@object['store']['book'][3]], JsonPath.new(path).on(@object)
  end

  def test_eval_with_floating_point_and_and
    assert_equal [@object['store']['book'][1]], JsonPath.new("$..book[?(@['price'] < 23.0 && @['price'] > 9.0)]").on(@object)
  end

  def test_eval_with_floating_point
    assert_equal [@object['store']['book'][1]], JsonPath.new("$..book[?(@['price'] == 13.0)]").on(@object)
  end

  def test_paths_with_underscores
    assert_equal [@object['store']['bicycle']['catalogue_number']], JsonPath.new('$.store.bicycle.catalogue_number').on(@object)
  end

  def test_path_with_hyphens
    assert_equal [@object['store']['bicycle']['single-speed']], JsonPath.new('$.store.bicycle.single-speed').on(@object)
  end

  def test_path_with_colon
    assert_equal [@object['store']['bicycle']['make:model']], JsonPath.new('$.store.bicycle.make:model').on(@object)
  end

  def test_paths_with_numbers
    assert_equal [@object['store']['bicycle']['2seater']], JsonPath.new('$.store.bicycle.2seater').on(@object)
  end

  def test_recognized_dot_notation_in_filters
    assert_equal [@object['store']['book'][2], @object['store']['book'][3]], JsonPath.new('$..book[?(@.isbn)]').on(@object)
  end

  def test_works_on_non_hash
    klass = Struct.new(:a, :b)
    object = klass.new('some', 'value')

    assert_equal ['value'], JsonPath.new('$.b').on(object)
  end

  def test_works_on_object
    klass = Class.new{
      attr_reader :b
      def initialize(b)
        @b = b
      end
    }
    object = klass.new("value")

    assert_equal ["value"], JsonPath.new('$.b').on(object)
  end

  def test_works_on_object_can_be_disabled
    klass = Class.new{
      attr_reader :b
      def initialize(b)
        @b = b
      end
    }
    object = klass.new("value")

    assert_equal [], JsonPath.new('$.b', allow_send: false).on(object)
  end

  def test_works_on_diggable
    klass = Class.new{
      attr_reader :h
      def initialize(h)
        @h = h
      end
      def dig(*keys)
        @h.dig(*keys)
      end
    }

    object = klass.new('a' => 'some', 'b' => 'value')
    assert_equal ['value'], JsonPath.new('$.b').on(object)

    object = {
      "foo" => klass.new('a' => 'some', 'b' => 'value')
    }
    assert_equal ['value'], JsonPath.new('$.foo.b').on(object)
  end

  def test_works_on_non_hash_with_filters
    klass = Struct.new(:a, :b)
    first_object = klass.new('some', 'value')
    second_object = klass.new('next', 'other value')

    assert_equal ['other value'], JsonPath.new('$[?(@.a == "next")].b').on([first_object, second_object])
  end

  def test_works_on_hash_with_summary
    object = {
      "foo" => [{
        "a" => "some",
        "b" => "value"
      }]
    }
    assert_equal [{ "b" => "value" }], JsonPath.new("$.foo[*](b)").on(object)
  end

  def test_works_on_non_hash_with_summary
    klass = Struct.new(:a, :b)
    object = {
      "foo" => [klass.new("some", "value")]
    }
    assert_equal [{ "b" => "value" }], JsonPath.new("$.foo[*](b)").on(object)
  end

  def test_recognize_array_with_evald_index
    assert_equal [@object['store']['book'][2]], JsonPath.new('$..book[(@.length-5)]').on(@object)
  end

  def test_use_first
    assert_equal @object['store']['book'][2], JsonPath.new('$..book[(@.length-5)]').first(@object)
  end

  def test_counting
    assert_equal 59, JsonPath.new('$..*').on(@object).to_a.size
  end

  def test_space_in_path
    assert_equal ['e'], JsonPath.new("$.'c d'").on('a' => 'a', 'b' => 'b', 'c d' => 'e')
  end

  def test_class_method
    assert_equal JsonPath.new('$..author').on(@object), JsonPath.on(@object, '$..author')
  end

  def test_join
    assert_equal JsonPath.new('$.store.book..author').on(@object), JsonPath.new('$.store').join('book..author').on(@object)
  end

  def test_gsub
    @object2['store']['bicycle']['price'] += 10
    @object2['store']['book'][0]['price'] += 10
    @object2['store']['book'][1]['price'] += 10
    @object2['store']['book'][2]['price'] += 10
    @object2['store']['book'][3]['price'] += 10
    assert_equal @object2, JsonPath.for(@object).gsub('$..price') { |p| p + 10 }.to_hash
  end

  def test_gsub!
    JsonPath.for(@object).gsub!('$..price') { |p| p + 10 }
    assert_equal 30, @object['store']['bicycle']['price']
    assert_equal 19, @object['store']['book'][0]['price']
    assert_equal 23, @object['store']['book'][1]['price']
    assert_equal 19, @object['store']['book'][2]['price']
    assert_equal 33, @object['store']['book'][3]['price']
  end

  def test_weird_gsub!
    h = { 'hi' => 'there' }
    JsonPath.for(@object).gsub!('$.*') { |_| h }
    assert_equal h, @object
  end

  def test_gsub_to_false!
    h = { 'hi' => 'there' }
    h2 = { 'hi' => false }
    assert_equal h2, JsonPath.for(h).gsub!('$.hi') { |_| false }.to_hash
  end

  def test_where_selector
    JsonPath.for(@object).gsub!('$..book.price[?(@ > 20)]') { |p| p + 10 }
  end

  def test_compact
    h = { 'hi' => 'there', 'you' => nil }
    JsonPath.for(h).compact!
    assert_equal({ 'hi' => 'there' }, h)
  end

  def test_delete
    h = { 'hi' => 'there', 'you' => nil }
    JsonPath.for(h).delete!('*.hi')
    assert_equal({ 'you' => nil }, h)
  end

  def test_delete_2
    json = { 'store' => {
      'book' => [
        { 'category' => 'reference',
          'author' => 'Nigel Rees',
          'title' => 'Sayings of the Century',
          'price' => 9,
          'tags' => %w[asdf asdf2] },
        { 'category' => 'fiction',
          'author' => 'Evelyn Waugh',
          'title' => 'Sword of Honour',
          'price' => 13 },
        { 'category' => 'fiction',
          'author' => 'Aasdf',
          'title' => 'Aaasdf2',
          'price' => 1 }
      ]
    } }
    json_deleted = { 'store' => {
      'book' => [
        { 'category' => 'fiction',
          'author' => 'Evelyn Waugh',
          'title' => 'Sword of Honour',
          'price' => 13 },
        { 'category' => 'fiction',
          'author' => 'Aasdf',
          'title' => 'Aaasdf2',
          'price' => 1 }
      ]
    } }
    assert_equal(json_deleted, JsonPath.for(json).delete("$..store.book[?(@.category == 'reference')]").obj)
  end

  def test_delete_3
    json = { 'store' => {
      'book' => [
        { 'category' => 'reference',
          'author' => 'Nigel Rees',
          'title' => 'Sayings of the Century',
          'price' => 9,
          'tags' => %w[asdf asdf2],
          'this' => {
            'delete_me' => [
              'no' => 'do not'
            ]
          } },
        { 'category' => 'fiction',
          'author' => 'Evelyn Waugh',
          'title' => 'Sword of Honour',
          'price' => 13 },
        { 'category' => 'fiction',
          'author' => 'Aasdf',
          'title' => 'Aaasdf2',
          'price' => 1 }
      ]
    } }
    json_deleted = { 'store' => {
      'book' => [
        { 'category' => 'reference',
          'author' => 'Nigel Rees',
          'title' => 'Sayings of the Century',
          'price' => 9,
          'tags' => %w[asdf asdf2],
          'this' => {} },
        { 'category' => 'fiction',
          'author' => 'Evelyn Waugh',
          'title' => 'Sword of Honour',
          'price' => 13 },
        { 'category' => 'fiction',
          'author' => 'Aasdf',
          'title' => 'Aaasdf2',
          'price' => 1 }
      ]
    } }
    assert_equal(json_deleted, JsonPath.for(json).delete('$..store.book..delete_me').obj)
  end

  def test_delete_for_array
    before = JsonPath.on(@object, '$..store.book[1]')
    JsonPath.for(@object).delete!('$..store.book[0]')
    after = JsonPath.on(@object, '$..store.book[0]')
    assert_equal(after, before, 'Before is the second element. After should have been equal to the next element after delete.')
  end

  def test_at_sign_in_json_element
    data =
      { '@colors' =>
      [{ '@r' => 255, '@g' => 0, '@b' => 0 },
       { '@r' => 0, '@g' => 255, '@b' => 0 },
       { '@r' => 0, '@g' => 0, '@b' => 255 }] }

    assert_equal [255, 0, 0], JsonPath.on(data, '$..@r')
  end

  def test_wildcard
    assert_equal @object['store']['book'].collect { |e| e['price'] }.compact, JsonPath.on(@object, '$..book[*].price')
  end

  def test_wildcard_on_intermediary_element
    assert_equal [1], JsonPath.on({ 'a' => { 'b' => { 'c' => 1 } } }, '$.a..c')
  end

  def test_wildcard_on_intermediary_element_v2
    assert_equal [1], JsonPath.on({ 'a' => { 'b' => { 'd' => { 'c' => 1 } } } }, '$.a..c')
  end

  def test_wildcard_on_intermediary_element_v3
    assert_equal [1], JsonPath.on({ 'a' => { 'b' => { 'd' => { 'c' => 1 } } } }, '$.a.*..c')
  end

  def test_wildcard_on_intermediary_element_v4
    assert_equal [1], JsonPath.on({ 'a' => { 'b' => { 'd' => { 'c' => 1 } } } }, '$.a.*..c')
  end

  def test_wildcard_on_intermediary_element_v5
    assert_equal [1], JsonPath.on({ 'a' => { 'b' => { 'c' => 1 } } }, '$.a.*.c')
  end

  def test_wildcard_on_intermediary_element_v6
    assert_equal ['red'], JsonPath.new('$.store.*.color').on(@object)
  end

  def test_wildcard_empty_array
    object = @object.merge('bicycle' => { 'tire' => [] })
    assert_equal [], JsonPath.on(object, '$..bicycle.tire[*]')
  end

  def test_support_filter_by_array_childnode_value
    assert_equal [@object['store']['book'][3]], JsonPath.new('$..book[?(@.price > 20)]').on(@object)
  end

  def test_support_filter_by_childnode_value_with_inconsistent_children
    @object['store']['book'][0] = 'string_instead_of_object'
    assert_equal [@object['store']['book'][3]], JsonPath.new('$..book[?(@.price > 20)]').on(@object)
  end

  def test_support_filter_by_childnode_value_and_select_child_key
    assert_equal [23], JsonPath.new('$..book[?(@.price > 20)].price').on(@object)
  end

  def test_support_filter_by_childnode_value_over_childnode_and_select_child_key
    assert_equal ['Osennie Vizity'], JsonPath.new('$..book[?(@.written.year == 1996)].title').on(@object)
  end

  def test_support_filter_by_object_childnode_value
    data = {
      'data' => {
        'type' => 'users',
        'id' => '123'
      }
    }
    assert_equal [{ 'type' => 'users', 'id' => '123' }], JsonPath.new("$.data[?(@.type == 'users')]").on(data)
    assert_equal [], JsonPath.new("$.[?(@.type == 'admins')]").on(data)
  end

  def test_support_at_sign_in_member_names
    assert_equal [@object['store']['@id']], JsonPath.new('$.store.@id').on(@object)
  end

  def test_support_dollar_sign_in_member_names
    assert_equal [@object['store']['$meta-data']],
                 JsonPath.new('$.store.$meta-data').on(@object)
  end

  def test_support_underscore_in_member_names
    assert_equal [@object['store']['_links']],
                 JsonPath.new('$.store._links').on(@object)
  end

  def test_support_for_umlauts_in_member_names
    assert_equal [@object['store']['Übermorgen']],
                 JsonPath.new('$.store.Übermorgen').on(@object)
  end

  def test_support_for_spaces_in_member_name
    assert_equal [@object['store']['Title Case']],
                 JsonPath.new('$.store.Title Case').on(@object)
  end

  def test_dig_return_string
    assert_equal ['asdf'], JsonPath.new("$.store.book..tags[?(@ == 'asdf')]").on(@object)
    assert_equal [], JsonPath.new("$.store.book..tags[?(@ == 'not_asdf')]").on(@object)
  end

  def test_slash_in_value
    data = {
      'data' => [{
        'type' => 'mps/awesome'
      }, {
        'type' => 'not'
      }]
    }
    assert_equal [{ 'type' => 'mps/awesome' }], JsonPath.new('$.data[?(@.type == "mps/awesome")]').on(data)
  end

  def test_floating_point_with_precision_marker
    data = {
      'data' => {
        'type' => 0.00001
      }
    }
    assert_equal [{ 'type' => 0.00001 }], JsonPath.new('$.data[?(@.type == 0.00001)]').on(data)
  end

  def test_digits_only_string
    data = {
      'foo' => {
        'type' => 'users',
        'id' => '123'
      }
    }
    assert_equal([{ 'type' => 'users', 'id' => '123' }], JsonPath.new("$.foo[?(@.id == '123')]").on(data))
  end

  def test_digits_only_string_in_array
    data = {
      'foo' => [{
        'type' => 'users',
        'id' => '123'
      }, {
        'type' => 'users',
        'id' => '321'
      }]
    }
    assert_equal([{ 'type' => 'users', 'id' => '123' }], JsonPath.new("$.foo[?(@.id == '123')]").on(data))
  end

  def test_at_in_filter
    jsonld = {
      'mentions' => [
        {
          'name' => 'Delimara Powerplant',
          'identifier' => 'krzana://took/powerstation/Delimara Powerplant',
          '@type' => 'Place',
          'geo' => {
            'latitude' => 35.83020073454,
            'longitude' => 14.55602645874
          }
        }
      ]
    }
    assert_equal(['Place'], JsonPath.new("$..mentions[?(@['@type'] == 'Place')].@type").on(jsonld))
  end

  def test_dollar_in_filter
    jsonld = {
      'mentions' => [
        {
          'name' => 'Delimara Powerplant',
          'identifier' => 'krzana://took/powerstation/Delimara Powerplant',
          '$type' => 'Place',
          'geo' => {
            'latitude' => 35.83020073454,
            'longitude' => 14.55602645874
          }
        }
      ]
    }
    assert_equal(['Place'], JsonPath.new("$..mentions[?(@['$type'] == 'Place')].$type").on(jsonld))
  end

  def test_underscore_in_filter
    jsonld = {
      'attributes' => [
        {
          'store' => [
            { 'with' => 'urn' },
            { 'with_underscore' => 'urn:1' }
          ]
        }
      ]
    }
    assert_equal(['urn:1'], JsonPath.new("$.attributes..store[?(@['with_underscore'] == 'urn:1')].with_underscore").on(jsonld))
  end

  def test_at_in_value
    jsonld = {
      'mentions' =>
         {
           'name' => 'Delimara Powerplant',
           'identifier' => 'krzana://took/powerstation/Delimara Powerplant',
           'type' => '@Place',
           'geo' => {
             'latitude' => 35.83020073454,
             'longitude' => 14.55602645874
           }
         }
    }
    assert_equal(['@Place'], JsonPath.new("$..mentions.type[?(@ == '@Place')]").on(jsonld))
  end

  def test_parens_in_value
    data = {
      'data' => {
        'number' => '(492) 080-3961'
      }
    }
    assert_equal [{ 'number' => '(492) 080-3961' }], JsonPath.new("$.data[?(@.number == '(492) 080-3961')]").on(data)
  end

  def test_boolean_parameter_value
    data = {
      'data' => [{
        'isTrue' => true,
        'name' => 'testname1'
      }, {
        'isTrue' => false,
        'name' => 'testname2'
      }]
    }

    # These queries should be equivalent
    expected = [{ 'isTrue' => true, 'name' => 'testname1' }]
    assert_equal expected, JsonPath.new('$.data[?(@.isTrue)]').on(data)
    assert_equal expected, JsonPath.new('$.data[?(@.isTrue==true)]').on(data)
    assert_equal expected, JsonPath.new('$.data[?(@.isTrue == true)]').on(data)

    # These queries should be equivalent
    expected = [{ 'isTrue' => false, 'name' => 'testname2' }]
    assert_equal expected, JsonPath.new('$.data[?(@.isTrue != true)]').on(data)
    assert_equal expected, JsonPath.new('$.data[?(@.isTrue!=true)]').on(data)
    assert_equal expected, JsonPath.new('$.data[?(@.isTrue==false)]').on(data)
  end

  def test_and_operator_with_boolean_parameter_value
    data = {
      'data' => [{
        'hasProperty1' => true,
        'hasProperty2' => false,
        'name' => 'testname1'
      }, {
        'hasProperty1' => false,
        'hasProperty2' => true,
        'name' => 'testname2'
      }, {
        'hasProperty1' => true,
        'hasProperty2' => true,
        'name' => 'testname3'
      }]
    }
    assert_equal ['testname3'], JsonPath.new('$.data[?(@.hasProperty1 && @.hasProperty2)].name').on(data)
  end

  def test_regex_simple
    assert_equal %w[asdf asdf2], JsonPath.new('$.store.book..tags[?(@ =~ /asdf/)]').on(@object)
    assert_equal %w[asdf asdf2], JsonPath.new('$.store.book..tags[?(@=~/asdf/)]').on(@object)
  end

  def test_regex_simple_miss
    assert_equal [], JsonPath.new('$.store.book..tags[?(@ =~ /wut/)]').on(@object)
  end

  def test_regex_r
    assert_equal %w[asdf asdf2], JsonPath.new('$.store.book..tags[?(@ =~ %r{asdf})]').on(@object)
  end

  def test_regex_flags
    assert_equal [
      @object['store']['book'][2],
      @object['store']['book'][4],
      @object['store']['book'][5],
      @object['store']['book'][6]
    ], JsonPath.new('$..book[?(@.author =~ /herman|lukyanenko/i)]').on(@object)
  end

  def test_regex_error
    assert_raises ArgumentError do
      JsonPath.new('$.store.book..tags[?(@ =~ asdf)]').on(@object)
    end
  end

  def test_regression_1
    json = {
      ok: true,
      channels: [
        {
          id: 'C09C5GYHF',
          name: 'general'
        },
        {
          id: 'C09C598QL',
          name: 'random'
        }
      ]
    }.to_json

    assert_equal 'C09C5GYHF', JsonPath.on(json, "$..channels[?(@.name == 'general')].id")[0]
  end

  def test_regression_2
    json = {
      ok: true,
      channels: [
        {
          id: 'C09C5GYHF',
          name: 'general',
          is_archived: false
        },
        {
          id: 'C09C598QL',
          name: 'random',
          is_archived: true
        }
      ]
    }.to_json

    assert_equal 'C09C5GYHF', JsonPath.on(json, '$..channels[?(@.is_archived == false)].id')[0]
  end

  def test_regression_3
    json = {
      ok: true,
      channels: [
        {
          id: 'C09C5GYHF',
          name: 'general',
          is_archived: false
        },
        {
          id: 'C09C598QL',
          name: 'random',
          is_archived: true
        }
      ]
    }.to_json

    assert_equal 'C09C598QL', JsonPath.on(json, '$..channels[?(@.is_archived)].id')[0]
  end

  def test_regression_4
    json = {
      ok: true,
      channels: [
        {
          id: 'C09C5GYHF',
          name: 'general',
          is_archived: false
        },
        {
          id: 'C09C598QL',
          name: 'random',
          is_archived: true
        }
      ]
    }.to_json

    assert_equal ['C09C5GYHF'], JsonPath.on(json, "$..channels[?(@.name == 'general')].id")
  end

  def test_regression_5
    json = {
      ok: true,
      channels: [
        {
          id: 'C09C5GYHF',
          name: 'general',
          is_archived: 'false'
        },
        {
          id: 'C09C598QL',
          name: 'random',
          is_archived: true
        }
      ]
    }.to_json

    assert_equal 'C09C5GYHF', JsonPath.on(json, "$..channels[?(@.is_archived == 'false')].id")[0]
  end

  def test_quote
    json = {
      channels: [
        {
          name: "King's Speech"
        }
      ]
    }.to_json

    assert_equal [{ 'name' => "King\'s Speech" }], JsonPath.on(json, "$..channels[?(@.name == 'King\'s Speech')]")
  end

  def test_curly_brackets
    data = {
      '{data}' => 'data'
    }
    assert_equal ['data'], JsonPath.new('$.{data}').on(data)
  end

  def test_symbolize
    data = '
    {
      "store": {
        "bicycle": {
          "price": 19.95,
          "color": "red"
        },
        "book": [
          {
            "price": 8.95,
            "category": "reference",
            "title": "Sayings of the Century",
            "author": "Nigel Rees"
          },
          {
            "price": 12.99,
            "category": "fiction",
            "title": "Sword of Honour",
            "author": "Evelyn Waugh"
          },
          {
            "price": 8.99,
            "category": "fiction",
            "isbn": "0-553-21311-3",
            "title": "Moby Dick",
            "author": "Herman Melville",
            "color": "blue"
          },
          {
            "price": 22.99,
            "category": "fiction",
            "isbn": "0-395-19395-8",
            "title": "The Lord of the Rings",
            "author": "Tolkien"
          }
        ]
      }
    }
    '
    assert_equal [{ price: 8.95, category: 'reference', title: 'Sayings of the Century', author: 'Nigel Rees' }, { price: 8.99, category: 'fiction', isbn: '0-553-21311-3', title: 'Moby Dick', author: 'Herman Melville', color: 'blue' }], JsonPath.new('$..book[::2]').on(data, symbolize_keys: true)
  end

  def test_changed
    json =
      {
        'snapshot' => {
          'objects' => {
            'whatever' => [
              {
                'column' => {
                  'name' => 'ASSOCIATE_FLAG',
                  'nullable' => true
                }
              },
              {
                'column' => {
                  'name' => 'AUTHOR',
                  'nullable' => false
                }
              }
            ]
          }
        }
      }
    assert_equal true, JsonPath.on(json, "$..column[?(@.name == 'ASSOCIATE_FLAG')].nullable")[0]
  end

  def test_another
    json = {
      initial: true,
      not: true
    }.to_json
    assert_equal [{ 'initial' => true, 'not' => true }], JsonPath.on(json, '$.[?(@.initial == true)]')
    json = {
      initial: false,
      not: true
    }.to_json
    assert_equal [], JsonPath.on(json, '$.initial[?(@)]')
    assert_equal [], JsonPath.on(json, '$.[?(@.initial == true)]')
    assert_equal [{ 'initial' => false, 'not' => true }], JsonPath.on(json, '$.[?(@.initial == false)]')
    json = {
      initial: 'false',
      not: true
    }.to_json
    assert_equal [{ 'initial' => 'false', 'not' => true }], JsonPath.on(json, "$.[?(@.initial == 'false')]")
    assert_equal [], JsonPath.on(json, '$.[?(@.initial == false)]')
  end

  def test_hanging
    json = { initial: true }.to_json
    success_path = '$.initial'
    assert_equal [true], JsonPath.on(json, success_path)
    broken_path = "$.initial\n"
    assert_equal [true], JsonPath.on(json, broken_path)
  end

  def test_complex_nested_grouping
    path = "$..book[?((@['author'] == 'Evelyn Waugh' || @['author'] == 'Herman Melville') && (@['price'] == 33 || @['price'] == 9))]"
    assert_equal [@object['store']['book'][2]], JsonPath.new(path).on(@object)
  end
  
  def test_nested_with_unknown_key
    path = "$..[?(@.price == 9 || @.price == 33)].title"
    assert_equal ["Sayings of the Century", "Moby Dick", "Sayings of the Century", "Moby Dick"], JsonPath.new(path).on(@object)
  end

  def test_nested_with_unknown_key_filtered_array
    path = "$..[?(@['price'] == 9 || @['price'] == 33)].title"
    assert_equal ["Sayings of the Century", "Moby Dick", "Sayings of the Century", "Moby Dick"], JsonPath.new(path).on(@object)
  end
  
  def test_runtime_error_frozen_string
    skip('in ruby version below 2.2.0 this error is not raised') if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.2.0') || Gem::Version.new(RUBY_VERSION) > Gem::Version::new('2.6')
    json = '
    {
      "test": "something"
    }
    '.to_json
    assert_raises(ArgumentError, "RuntimeError: character '|' not supported in query") do
      JsonPath.on(json, '$.description|title')
    end
  end

  def test_delete_more_items
    a = { 'itemList' =>
      [{ 'alfa' => 'beta1' },
       { 'alfa' => 'beta2' },
       { 'alfa' => 'beta3' },
       { 'alfa' => 'beta4' },
       { 'alfa' => 'beta5' },
       { 'alfa' => 'beta6' },
       { 'alfa' => 'beta7' },
       { 'alfa' => 'beta8' },
       { 'alfa' => 'beta9' },
       { 'alfa' => 'beta10' },
       { 'alfa' => 'beta11' },
       { 'alfa' => 'beta12' }] }
    expected = { 'itemList' => [{ 'alfa' => 'beta1' }] }
    assert_equal expected, JsonPath.for(a.to_json).delete('$.itemList[1:12:1]').to_hash
  end

  def test_delete_more_items_with_stepping
    a = { 'itemList' =>
      [{ 'alfa' => 'beta1' },
       { 'alfa' => 'beta2' },
       { 'alfa' => 'beta3' },
       { 'alfa' => 'beta4' },
       { 'alfa' => 'beta5' },
       { 'alfa' => 'beta6' },
       { 'alfa' => 'beta7' },
       { 'alfa' => 'beta8' },
       { 'alfa' => 'beta9' },
       { 'alfa' => 'beta10' },
       { 'alfa' => 'beta11' },
       { 'alfa' => 'beta12' }] }
    expected = { 'itemList' =>
    [{ 'alfa' => 'beta1' },
     { 'alfa' => 'beta3' },
     { 'alfa' => 'beta5' },
     { 'alfa' => 'beta7' },
     { 'alfa' => 'beta8' },
     { 'alfa' => 'beta9' },
     { 'alfa' => 'beta10' },
     { 'alfa' => 'beta11' },
     { 'alfa' => 'beta12' }] }
    assert_equal expected, JsonPath.for(a.to_json).delete('$.itemList[1:6:2]').to_hash
  end

  def test_nested_values
    json = '
    {
      "phoneNumbers": [
        [{
          "type"  : "iPhone",
          "number": "0123-4567-8888"
        }],
        [{
          "type"  : "home",
          "number": "0123-4567-8910"
        }]
      ]
    }
    '.to_json
    assert_equal [[{ 'type' => 'home', 'number' => '0123-4567-8910' }]], JsonPath.on(json, "$.phoneNumbers[?(@[0].type == 'home')]")
    assert_equal [], JsonPath.on(json, "$.phoneNumbers[?(@[2].type == 'home')]")
    json = '
    {
      "phoneNumbers":
        {
          "type"  : "iPhone",
          "number": "0123-4567-8888"
        }
    }
    '.to_json
    assert_equal [], JsonPath.on(json, "$.phoneNumbers[?(@[0].type == 'home')]")
  end

  def test_selecting_multiple_keys_on_hash
    json = '
    {
      "category": "reference",
      "author": "Nigel Rees",
      "title": "Sayings of the Century",
      "price": 8.95
    }
    '.to_json
    assert_equal [{ 'category' => 'reference', 'author' => 'Nigel Rees' }], JsonPath.on(json, '$.(category,author)')
  end

  def test_selecting_multiple_keys_on_sub_hash
    skip("Failing as the semantics of .(x,y) is unclear")
    json = '
    {
      "book": {
        "category": "reference",
        "author": "Nigel Rees",
        "title": "Sayings of the Century",
        "price": 8.95
      }
    }
    '.to_json
    assert_equal [{ 'category' => 'reference', 'author' => 'Nigel Rees' }], JsonPath.on(json, '$.book.(category,author)')
  end

  def test_selecting_multiple_keys_on_array
    json = '
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
    }
    '.to_json

    assert_equal [{ 'category' => 'reference', 'author' => 'Nigel Rees' }, { 'category' => 'fiction', 'author' => 'Evelyn Waugh' }], JsonPath.on(json, '$.store.book[*](category,author)')
  end

  def test_selecting_multiple_keys_on_array_with_filter
    json = '
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
    }
    '.to_json

    assert_equal [{ 'category' => 'reference', 'author' => 'Nigel Rees' }], JsonPath.on(json, "$.store.book[?(@['price'] == 8.95)](category,author)")
    assert_equal [{ 'category' => 'reference', 'author' => 'Nigel Rees' }], JsonPath.on(json, "$.store.book[?(@['price'] == 8.95)](   category, author   )")
  end

  def test_selecting_multiple_keys_with_filter_with_space_in_catergory
    json = '
    {
      "store": {
        "book": [
          {
            "cate gory": "reference",
            "author": "Nigel Rees",
            "title": "Sayings of the Century",
            "price": 8.95
          },
          {
            "cate gory": "fiction",
             "author": "Evelyn Waugh",
             "title": "Sword of Honour",
             "price": 12.99
          }
        ]
      }
    }
    '.to_json

    assert_equal [{ 'cate gory' => 'reference', 'author' => 'Nigel Rees' }], JsonPath.on(json, "$.store.book[?(@['price'] == 8.95)](   cate gory, author   )")
  end

  def test_use_symbol_opt
    json = {
      store: {
        book: [
          {
            category: "reference",
            author: "Nigel Rees",
            title: "Sayings of the Century",
            price: 8.95
          },
          {
            category: "fiction",
            author: "Evelyn Waugh",
            title: "Sword of Honour",
            price: 12.99
          }
        ]
      }
    }
    on = ->(path){ JsonPath.on(json, path, use_symbols: true) }
    assert_equal ['reference', 'fiction'], on.("$.store.book[*].category")
    assert_equal ['reference', 'fiction'], on.("$..category")
    assert_equal ['reference'], on.("$.store.book[?(@['price'] == 8.95)].category")
    assert_equal [{'category' => 'reference'}], on.("$.store.book[?(@['price'] == 8.95)](category)")
  end

  def test_object_method_send
    j = {height: 5, hash: "some_hash"}.to_json
    hs = JsonPath.new "$..send"
    assert_equal([], hs.on(j))
    hs = JsonPath.new "$..hash"
    assert_equal(["some_hash"], hs.on(j))
    hs = JsonPath.new "$..send"
    assert_equal([], hs.on(j))
    j = {height: 5, send: "should_still_work"}.to_json
    hs = JsonPath.new "$..send"
    assert_equal(['should_still_work'], hs.on(j))
  end

  def test_index_access_by_number
    data = {
      '1': 'foo'
    }
    assert_equal ['foo'], JsonPath.new('$.1').on(data.to_json)
  end

  def test_behavior_on_null_and_missing
    data = {
      "foo" => nil,
      "bar" => {
        "baz" => nil
      },
      "bars" => [
        { "foo" => 12 },
        { "foo" => nil },
        { }
      ]
    }
    assert_equal [nil], JsonPath.new('$.foo').on(data)
    assert_equal [nil], JsonPath.new('$.bar.baz').on(data)
    assert_equal [], JsonPath.new('$.baz').on(data)
    assert_equal [], JsonPath.new('$.bar.foo').on(data)
    assert_equal [12, nil], JsonPath.new('$.bars[*].foo').on(data)
  end

  def test_default_path_leaf_to_null_opt
    data = {
      "foo" => nil,
      "bar" => {
        "baz" => nil
      },
      "bars" => [
        { "foo" => 12 },
        { "foo" => nil },
        { }
      ]
    }
    assert_equal [nil], JsonPath.new('$.foo', default_path_leaf_to_null: true).on(data)
    assert_equal [nil], JsonPath.new('$.bar.baz', default_path_leaf_to_null: true).on(data)
    assert_equal [nil], JsonPath.new('$.baz', default_path_leaf_to_null: true).on(data)
    assert_equal [nil], JsonPath.new('$.bar.foo', default_path_leaf_to_null: true).on(data)
    assert_equal [12, nil, nil], JsonPath.new('$.bars[*].foo', default_path_leaf_to_null: true).on(data)
  end

  def test_raise_max_nesting_error
    json = {
      a: {
        b: {
          c: {
          }
        }
      }
    }.to_json

    assert_raises(MultiJson::ParseError) { JsonPath.new('$.a', max_nesting: 1).on(json) }
  end

  def test_linefeed_in_path_error
    assert_raises(ArgumentError) { JsonPath.new("$.store\n.book") }
  end

  def test_with_max_nesting_false
    json = {
      a: {
        b: {
          c: {
          }
        }
      }
    }.to_json

    assert_equal [{}], JsonPath.new('$.a.b.c', max_nesting: false).on(json)
  end

  def test_initialize_with_max_nesting_exceeding_limit
    json = {
      a: {
        b: {
          c: {
          }
        }
      }
    }.to_json

    json_obj = JsonPath.new('$.a.b.c', max_nesting: 105)
    assert_equal [{}], json_obj.on(json)
    assert_equal false, json_obj.instance_variable_get(:@opts)[:max_nesting]
  end

  def test_initialize_without_max_nesting_exceeding_limit
    json_obj = JsonPath.new('$.a.b.c', max_nesting: 90)
    assert_equal 90, json_obj.instance_variable_get(:@opts)[:max_nesting]
  end

  def test_initialize_with_max_nesting_false_limit
    json_obj = JsonPath.new('$.a.b.c', max_nesting: false)
    assert_equal false, json_obj.instance_variable_get(:@opts)[:max_nesting]
  end

  def example_object
    { 'store' => {
      'book' => [
        { 'category' => 'reference',
          'author' => 'Nigel Rees',
          'title' => 'Sayings of the Century',
          'price' => 9,
          'tags' => %w[asdf asdf2] },
        { 'category' => 'fiction',
          'author' => 'Evelyn Waugh',
          'title' => 'Sword of Honour',
          'price' => 13 },
        { 'category' => 'fiction',
          'author' => 'Herman Melville',
          'title' => 'Moby Dick',
          'isbn' => '0-553-21311-3',
          'price' => 9 },
        { 'category' => 'fiction',
          'author' => 'J. R. R. Tolkien',
          'title' => 'The Lord of the Rings',
          'isbn' => '0-395-19395-8',
          'price' => 23 },
        { 'category' => 'russian_fiction',
          'author' => 'Lukyanenko',
          'title' => 'Imperatory Illuziy',
          'written' => {
            'year' => 1995
          } },
        { 'category' => 'russian_fiction',
          'author' => 'Lukyanenko',
          'title' => 'Osennie Vizity',
          'written' => {
            'year' => 1996
          } },
        { 'category' => 'russian_fiction',
          'author' => 'Lukyanenko',
          'title' => 'Ne vremya dlya drakonov',
          'written' => {
            'year' => 1997
          } }
      ],
      'bicycle' => {
        'color' => 'red',
        'price' => 20,
        'catalogue_number' => 123_45,
        'single-speed' => 'no',
        '2seater' => 'yes',
        'make:model' => 'Zippy Sweetwheeler'
      },
      '@id' => 'http://example.org/store/42',
      '$meta-data' => 'whatevs',
      'Übermorgen' => 'The day after tomorrow',
      'Title Case' => 'A title case string',
      '_links' => { 'self' => {} }
    } }
  end

  def test_fetch_all_path
    data = {
      "foo" => nil,
      "bar" => {
        "baz" => nil
      },
      "bars" => [
        { "foo" => 12 },
        { "foo" => nil },
        { }
      ]
    }
    assert_equal ["$", "$.foo", "$.bar", "$.bar.baz", "$.bars", "$.bars[0].foo", "$.bars[0]", "$.bars[1].foo", "$.bars[1]", "$.bars[2]"], JsonPath.fetch_all_path(data)
  end


  def test_extractore_with_dollar_key
    json = {"test" => {"$" =>"success", "a" => "123"}}
    assert_equal ["success"],  JsonPath.on(json, "$.test.$")
    assert_equal ["123"],  JsonPath.on(json, "$.test.a")
  end

  def test_symbolize_key
    data = { "store" => { "book" => [{"category" => "reference"}]}}
    assert_equal [{"category": "reference"}],  JsonPath.new('$..book[0]', symbolize_keys: true).on(data)
    assert_equal [{"category": "reference"}],  JsonPath.new('$..book[0]').on(data, symbolize_keys: true)
  end
end
