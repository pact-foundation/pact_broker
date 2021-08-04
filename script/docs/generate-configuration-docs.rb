#!/usr/bin/env ruby

require 'yaml'

$stream = StringIO.new

def write string
  $stream.puts string
end

def escape_backticks value
  if value.is_a?(String)
    value.gsub('`', '``')
  else
    value
  end
end

docs_dir = File.expand_path('../../../docs', __FILE__)
environment_variable_file = File.join(docs_dir, 'configuration.yml')
doc = YAML.load(File.read(environment_variable_file))

write "# Pact Broker Configuration\n\n"
# write "## Index"

# doc['groups'].each do | group |
#   write "* #{group['title']}\n"

#   group['vars'].each do | name, metadata |
#     next if metadata['hidden']
#     write "    * [#{name}](##{name})\n"
#   end
# end

write "\n"

doc['groups'].each do | group |
  write "<br/>\n\n"
  write "## #{group['title']}\n\n<hr/>\n"
  if group['comments']
    write group['comments']
  end
  write "\n\n"

  group['vars'].each do | name, metadata |
    next if metadata['hidden']
    write "### #{name}\n\n"
    write "#{metadata['description']}\n\n"

    write "**Required:** #{metadata['required'] || 'false'}<br/>"
    write "**Format:** #{metadata['format']}<br/>" if metadata['format']
    write "**Default:** `#{metadata['default']}`<br/>" if metadata['default']
    if metadata['allowed_values']
      allowed_values = metadata['allowed_values'].collect{ |val| "`#{escape_backticks(val)}`"}.join(', ')
      write "**Allowed values:** #{allowed_values}<br/>"
    end
    write "**Example:** `#{metadata['example']}`<br/>" if metadata['example']
    if metadata['examples']
      allowed_values = metadata['examples'].collect{ |val| "`#{escape_backticks(val)}`"}.join(', ')
      write "**Examples:** #{allowed_values}<br/>"
    end
    write "**More information:** #{metadata['more_info']}<br/>" if metadata['more_info']
    write "\n"
  end
end

File.open(File.join(docs_dir, 'CONFIGURATION.md'), "w") { |file| file << $stream.string }

required_env_vars = []

doc['groups'].each do | group |
  group['vars'].each do | name, metadata |
    required_env_vars << name if metadata['required'] && !metadata['default']
  end
end

puts "Required:"
puts required_env_vars
