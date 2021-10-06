#!/usr/bin/env ruby
require "json"
require "pathname"
require "fileutils"

EXAMPLES_FILE_PATTERN = "spec/fixtures/approvals/docs_*"
API_DOCS_DIR = Pathname.new("docs/api")


class Category
  attr_reader :name, :examples, :not_options_examples

  def initialize(name, examples)
    @name = name
    @examples = examples
    @options_example = examples.select { | example | example[:request][:method] == "OPTIONS" }.first
    @not_options_examples = examples.select { | example | example[:request][:method] != "OPTIONS" }
  end

  def path_template
    not_options_examples.first[:request][:path_template]
  end

  def allowed_methods
    if options_example
      options_example[:response][:headers][:'Access-Control-Allow-Methods'].split(",").collect(&:strip).reject { |m| m == "OPTIONS" }
    else
      []
    end
  end

  private

  attr_reader :other_examples, :options_example

end

def generate_example_markdown_for_examples(name, examples)
  category = Category.new(name, examples)


  not_options_docs = category.not_options_examples.collect { | example | generate_example_markdown(example) }

  allowed_methods = category.allowed_methods.collect{ | meth| "`#{meth}`"}.join(", ")

"
## #{name}

Path: `#{category.path_template}`<br/>
Allowed methods: #{allowed_methods}<br/>
#{not_options_docs.join("\n")}
"
end

def generate_example_markdown(hash)
"
### #{hash[:request][:method]}

#### Request

Headers: `#{hash[:request][:headers]&.to_json}`<br/>

#### Response

Status: `#{hash[:response][:status]}`<br/>
Headers: `#{hash[:response][:headers]&.to_json}`<br/>
Body:

```
#{body_markdown(hash[:response][:body])}
```
"
end

def body_markdown(body)
  body.is_a?(Hash) ? JSON.pretty_generate(body) : body
end

file_names = Dir.glob(EXAMPLES_FILE_PATTERN)

examples = file_names.collect do | file_name |
  JSON.parse(File.read(file_name), symbolize_names: true)
end

examples_by_category = examples.group_by { | hash | hash[:category] }

FileUtils.rm_rf(API_DOCS_DIR)
FileUtils.mkdir_p(API_DOCS_DIR)

examples_by_category.each do | category, examples |

  examples_by_name = examples.sort_by{ |hash| hash[:order] }.group_by { | hash | hash[:name] }

  docs = examples_by_name.collect do | name, examples |
    generate_example_markdown_for_examples(name, examples)
  end

  file_name = (API_DOCS_DIR / category.upcase).to_s + ".md"
  contents = "
# #{category}

#{docs.join("\n")}
"

  File.open(file_name, "w") { |file| file << contents }
end