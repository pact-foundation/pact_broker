require 'spec_helper'


describe Approvals::Filter do
  it "When no filters were supplied, it leaves the h_or_a alone" do
    filter = Approvals::Filter.new({})

    input = {some: 'hash'}
    output = filter.apply(input)

    expect(input).to equal output
  end

  it "replaces fields which match a filter" do
    filter = Approvals::Filter.new({foo: /^_?foo$/})
    input = {
      foo: 'bar13',
      _foo: 'bar27',
      nonfoo: 'bar',
    }

    output = filter.apply(input)

    expect(output).to eq({
      foo: '<foo>',
      _foo: '<foo>',
      nonfoo: 'bar',
    })
  end

  it "a filter matches, but the value is nil, it does not get replaced" do
    filter = Approvals::Filter.new({foo: /^foo$/})
    input = {
      foo: nil,
      nonfoo: 'bar',
    }

    output = filter.apply(input)

    expect(output).to eq({
      foo: nil,
      nonfoo: 'bar',
    })
  end
  it "a filter matches, and the value is falsey, but not nil, it gets replaced" do
    filter = Approvals::Filter.new({foo: /^foo$/})
    input = {
      foo: false,
      nonfoo: 'bar',
    }

    output = filter.apply(input)

    expect(output).to eq({
      foo: "<foo>",
      nonfoo: 'bar',
    })
  end

  it "filters recursively in hashes and array" do
    filter = Approvals::Filter.new({foo: /^foo$/})
    input = {
      foo: 'bar124',
      foolist: [{foo: 'bar 145', bar: 'foo'}, 'foobar'],
      nonfoo: 'bar',
    }

    output = filter.apply(input)

    expect(output).to eq({
      foo: '<foo>',
      foolist: [{foo: '<foo>', bar: 'foo'}, 'foobar'],
      nonfoo: 'bar',
    })
  end

  it "filters array keys" do
    filter = Approvals::Filter.new({foolist: /^foolist$/})
    input = {
      foo: 'bar124',
      foolist: [{foo: 'bar 145', bar: 'foo'}, 'foobar'],
      nonfoo: 'bar',
    }

    output = filter.apply(input)

    expect(output).to eq({
      foo: 'bar124',
      foolist: '<foolist>',
      nonfoo: 'bar',
    })
  end

  it "filters hash keys" do
    filter = Approvals::Filter.new({foohash: /^foohash$/})
    input = {
      foo: 'bar124',
      foohash: {foo: 'bar 145', barlist: ['foo', 'bar']},
      nonfoo: 'bar',
    }

    output = filter.apply(input)

    expect(output).to eq({
      foo: 'bar124',
      foohash: '<foohash>',
      nonfoo: 'bar',
    })
  end

  it "takes the last applicable filter" do
    filter = Approvals::Filter.new({foo: /^foo/, bar: /bar$/})
    input = {
      foobar: 'baz',
    }

    output = filter.apply(input)

    expect(output).to eq({
      foobar: '<bar>',
    })
  end
end
