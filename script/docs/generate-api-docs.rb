#!/usr/bin/env ruby
require "json"
require "pathname"
require "fileutils"

EXAMPLES_FILE_PATTERN = "spec/fixtures/approvals/docs_*"
API_DOCS_DIR = Pathname.new("docs/api")

def generate_example_markdown(hash)
"
## #{hash[:name]}

### Request

Method: `#{hash[:request][:method]}`<br/>
Path: `#{hash[:request][:path_template]}`<br/>
Headers: `#{hash[:request][:headers]&.to_json}`<br/>

### Response

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

hashes = file_names.collect do | file_name |
  JSON.parse(File.read(file_name), symbolize_names: true)
end

hashes_by_category = hashes.group_by { | hash | hash[:category] }

FileUtils.rm_rf(API_DOCS_DIR)
FileUtils.mkdir_p(API_DOCS_DIR)

hashes_by_category.each do | category, hashes |
  docs = hashes.collect do | hash |
    generate_example_markdown(hash)
  end

  file_name = (API_DOCS_DIR / category.upcase).to_s + ".md"
  contents = "
# #{category}

#{docs.join("\n")}
"

  File.open(file_name, "w") { |file| file << contents }
end