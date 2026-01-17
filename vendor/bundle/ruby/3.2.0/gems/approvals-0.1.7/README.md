# Approvals

[![Build](https://github.com/approvals/ApprovalTests.Ruby/actions/workflows/test.yml/badge.svg)](https://github.com/approvals/ApprovalTests.Ruby/actions/workflows/test.yml)[![Gem Version](https://badge.fury.io/rb/approvals.svg)](http://badge.fury.io/rb/approvals)
[![Code Climate](https://codeclimate.com/github/kytrinyx/approvals.svg)](https://codeclimate.com/github/kytrinyx/approvals)
[![Gemnasium](https://gemnasium.com/kytrinyx/approvals.svg)](https://gemnasium.com/kytrinyx/approvals)

<!-- toc -->
## Contents

  * [Getting Started](#getting-started)
    * [New Projects](#new-projects)
  * [Configuration](#configuration)
  * [Usage](#usage)
    * [Customizing formatted output](#customizing-formatted-output)
  * [CLI](#cli)
    * [Workflow Using VimDiff](#workflow-using-vimdiff)
    * [RSpec](#rspec)
    * [Naming](#naming)
    * [Formatting](#formatting)
    * [Exclude dynamically changed values from json](#exclude-dynamically-changed-values-from-json)
    * [Approving a spec](#approving-a-spec)
    * [Expensive computations](#expensive-computations)
    * [RSpec executable](#rspec-executable)
  * [Example use cases](#example-use-cases)
    * [Verifying complex SQL in Rails](#verifying-complex-sql-in-rails)<!-- endToc -->

Approvals are based on the idea of the *_golden master_*.

You take a snapshot of an object, and then compare all future
versions of the object to the snapshot.

Big hat tip to Llewellyn Falco who developed the approvals concept, as
well as the original approvals libraries (.NET, Java, Ruby, PHP,
probably others).

See [ApprovalTests](http://www.approvaltests.com) for videos and additional documentation about the general concept.

Also, check out  Herding Code's [podcast #117](http://t.co/GLn88R5) in
which Llewellyn Falco is interviewed about approvals.
## Getting Started

### New Projects

The easiest way to get started with a new project is to clone the [Starter Project](https://github.com/approvals/ApprovalTests.Ruby.starterproject)
## Configuration

<!-- snippet: config-example -->
<a id='snippet-config-example'></a>
```rb
Approvals.configure do |config|
  config.approvals_path = 'output/dir/'
end
```
<sup><a href='/spec/configuration_spec.rb#L12-L16' title='Snippet source file'>snippet source</a> | <a href='#snippet-config-example' title='Start of snippet'>anchor</a></sup>
<!-- endSnippet -->

The default location for the output files is

```plain
approvals/
```

## Usage

```ruby
Approvals.verify(your_subject, :format => :json)
```

This will raise an `ApprovalError` in the case of a failure.

The first time the approval is run, a file will be created with the contents of the subject of your approval:

    the_name_of_the_approval.received.txt # or .json, .html, .xml as appropriate

Since you have not yet approved anything, the `*.approved` file does not exist, and the comparison will fail.

### Customizing formatted output

The default writer uses the `:to_s` method on the subject to generate the output for the received file.
For custom complex objects you will need to provide a custom writer to get helpful output, rather than the default:

    #<Object:0x0000010105ea40> # or whatever the object id is

Create a custom writer class somewhere accessible to your test:

```
class MyCustomWriter < Approvals::Writers::TextWriter
  def format(data)
    # Custom data formatting here
  end

  def filter(data)
    # Custom data filtering here
  end
end
```

In your test, use a string to reference your custom class:

```
it "verifies a complex object" do
  Approvals.verify hello, :format => "MyCustomWriter"
end
```

Define and use different custom writers as needed!

## CLI

The gem comes with a command-line tool that makes it easier to manage the
`*.received.*` and `*.approved.*` files.

The basic usage is:

```bash
approvals verify
```

This goes through each approval failure in turn showing you the diff.

The option `--diff` or `-d` configures which difftool to use (for example
`opendiff`, `vimdiff`, etc). The default value is `diff`.

The option `--ask` or `-a`, which after showing you a diff will offer to
approve the received file (move it from `*.received.*` to `*.approved.*`.).
The default is `true`. If you set this to `false`, then nothing happens beyond
showing you the diff, and you will need to rename files manually.

### Workflow Using VimDiff

I have the following mapped to `<leader>v` in my .vimrc file:

```viml
map <leader>v :!approvals verify -d vimdiff -a<cr>
```

I tend to run my tests from within vim with an on-the-fly mapping:

```viml
:map Q :wa <Bar> :!ruby path/to/test_file.rb<cr>
```

When I get one or more approval failures, I hit `<leader>v`. This gives me the
vimdiff.

When I've inspected the result, I hit `:qa` which closes both sides of the
diff.

Then I'm asked if I want to approve the received file `[yN]`. If there are
multiple diffs, this handles each failure in turn.

### RSpec

For the moment the only direct integration is with RSpec.

```ruby
require 'approvals/rspec'
```

The default directory for output files when using RSpec is

```ruby
spec/fixtures/approvals/
```

You can override this:

```ruby
RSpec.configure do |config|
  config.approvals_path = 'some/other/path'
end
```

The basic format of the approval is modeled after RSpec's `it`:

```ruby
it 'works' do
  verify do
    'this is the the thing you want to verify'
  end
end
```

### Naming

When using RSpec, the namer is set for you, using the example's `full_description`.

```ruby
Approvals.verify(thing, :name => 'the name of your test')
```

### Formatting

You can pass a format for your output before it gets written to the file.
At the moment, only text, xml, html, and json are supported, while text is the default.

Simply add a `:format => :txt`, `:format => :xml`, `:format => :html`, or `:format => :json` option to the example:

```ruby
page = '<html><head></head><body><h1>ZOMG</h1></body></html>'
Approvals.verify page, :format => :html

data = '{\'beverage\':\'coffee\'}'
Approvals.verify data, :format => :json
```

In RSpec, it looks like this:

```ruby
verify :format => :html do
  '<html><head></head><body><h1>ZOMG</h1></body></html>'
end

verify :format => :json do
  '{\'beverage\':\'coffee\'}'
end
```

If you like you could also change the default format globally with:

```ruby
RSpec.configure do |config|
  config.approvals_default_format = :json # or :xml, :html
end
```

### Exclude dynamically changed values from json

```ruby
Approvals.configure do |config|
  config.excluded_json_keys = {
    :id =>/(\A|_)id$/,
    :date => /_at$/
  }
end
```

It will replace values with placeholders:

    {id: 5, created_at: "2013-08-29 13:48:08 -0700"}

=>

    {id: "<id>", created_at: "<date>"}

### Approving a spec

If the contents of the received file is to your liking, you can approve
the file by renaming it.

For an example who's full description is `My Spec`:

    mv my_spec.received.txt my_spec.approved.txt

When you rerun the approval, it should now pass.

### Expensive computations

The Executable class allows you to perform expensive operations only when the command to execute it changes.

For example, if you have a SQL query that is very slow, you can create an executable with the actual SQL to be performed.

The first time the spec runs, it will fail, allowing you to inspect the results.
If this output looks right, approve the query. The next time the spec is run, it will compare only the actual SQL.

If someone changes the query, then the comparison will fail. Both the previously approved command and the received command will be executed so that you can inspect the difference between the results of the two.

```ruby
executable = Approvals::Executable.new(subject.slow_sql) do |output|
  # do something on failure
end

Approvals.verify(executable, :options => :here)
```

### RSpec executable

There is a convenience wrapper for RSpec that looks like so:

```ruby
verify do
  executable(subject.slow_sql) do |command|
     result = ActiveRecord::Base.connection.execute(command)
     # do something to display the result
  end
end
```

## Example use cases

### Verifying complex SQL in Rails

If you're using Rails and want to avoid accidentally introducing N+1 database queries, you can define a `verify_sql` helper like so:

```ruby
# spec/spec_helper.rb

require "./spec/support/approvals_helper"

RSpec.configure do |config|
  config.include ApprovalsHelper
end

# spec/support/approvals_helper.rb

module ApprovalsHelper
  def verify_sql(&block)
    sql = []

    subscriber = ->(_name, _start, _finish, _id, payload) do
      sql << payload[:sql].split("/*").first.gsub(/\d+/, "?")
    end

    ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record", &block)

    verify :format => :txt do
      sql.join("\n") + "\n"
    end
  end
end

# spec/models/example_spec.rb

it "is an example spec" do
   verify_sql do
     expect(Thing.complex_query).to eq(expected_things)
   end
 end
```

This `verify_sql` can be useful in model or integration tests; anywhere you're worried about the SQL being generated by complex queries, API endpoints, GraphQL fields, etc.

Copyright (c) 2011 Katrina Owen, released under the MIT license
