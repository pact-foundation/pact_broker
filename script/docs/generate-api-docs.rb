#!/usr/bin/env ruby
require "json"
require "pathname"
require "fileutils"

EXAMPLES_FILE_PATTERN = "spec/fixtures/approvals/docs_*"
API_DOCS_DIR = Pathname.new("docs/api")

def generate_example_markdown_for_examples(name, examples)
  options = examples.select { | example | example[:request][:method] == "OPTIONS" }.first
  other = examples.select { | example | example[:request][:method] != "OPTIONS" }

  not_options_docs = other.collect { | example | generate_example_markdown(example) }

"
## #{name}

Allowed methods: #{options && options[:response][:headers][:'Access-Control-Allow-Methods']}
#{not_options_docs.join("\n")}
"
end

def generate_example_markdown(hash)
"
### #{hash[:request][:method]}

#### Request

Path: `#{hash[:request][:path_template]}`<br/>
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

  examples_by_name = examples.group_by { | hash | hash[:name] }

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