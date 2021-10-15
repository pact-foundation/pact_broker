#!/usr/bin/env ruby

INTRO = <<EOM
<!-- This is a generated file. Please do not edit it directly. The source is https://github.com/pact-foundation/pact_broker/blob/master/docs/configuration.yml -->

The Pact Broker supports configuration via environment variables or a YAML file from version 2.87.0.1 of the Docker images.

To configure the application using a YAML file, place it in the location `config/pact_broker.yml`,
relative to the working directory of the application, or set the environment
variable `PACT_BROKER_CONF` to the full path to the configuration file.
EOM

require "yaml"
$stream = StringIO.new

def write string
  $stream.puts string
end

def escape_backticks value
  if value.is_a?(String)
    value.gsub("`", "``")
  else
    value
  end
end

def in_backticks value
  if value =~ /\s\(.+\)/
    "`#{escape_backticks(value)}".gsub(" (", "` (")
  else
    "`#{escape_backticks(value)}`"
  end
end

docs_dir = File.expand_path("../../../docs", __FILE__)
configuration_doc_path = File.join(docs_dir, "CONFIGURATION.md")
environment_variable_file = File.join(docs_dir, "configuration.yml")
doc = YAML.load(File.read(environment_variable_file))

write "# Pact Broker Configuration\n\n"
# write "## Index"

# doc["groups"].each do | group |
#   write "* #{group['title']}\n"

#   group['vars'].each do | name, metadata |
#     next if metadata['hidden']
#     write "    * [#{name}](##{name})\n"
#   end
# end

write "\n"

write INTRO

doc["groups"].each do | group |
  write "<br/>\n\n"
  write "## #{group["title"]}\n\n<hr/>\n"
  if group["comments"]
    write group["comments"]
  end
  write "\n\n"

  group["vars"].each do | name, metadata |
    next if metadata["hidden"]
    write "### #{name}\n\n"
    write "#{metadata["description"]}\n\n"

    write "**YAML configuration key name:** #{in_backticks(name)}<br/>"
    write "**Environment variable name:** `PACT_BROKER_#{name.upcase}`<br/>"
    write "**Supported versions:** #{metadata["supported_versions"]}<br/>" if metadata["supported_versions"]
    write "**Required:** #{metadata["required"] || "false"}<br/>" if metadata["required"]
    write "**Format:** #{metadata["format"]}<br/>" if metadata["format"]

    write "**Default:** #{in_backticks(metadata["default_value"])}<br/>" if !metadata["default_value"].nil?
    write "**Default:** #{metadata["default_description"]}<br/>" if !metadata["default_description"].nil?
    if metadata["allowed_values_description"]
      write "**Allowed values:** #{metadata["allowed_values_description"]}<br/>"
    end
    if metadata["allowed_values"]
      allowed_values = metadata["allowed_values"].collect{ |val| in_backticks(val) }.join(", ")
      write "**Allowed values:** #{allowed_values}<br/>"
    end
    write "**Example:** #{in_backticks(metadata["example"]) }<br/>" if metadata["example"]
    if metadata["examples"]
      allowed_values = metadata["examples"].collect{ |val| in_backticks(val) }.join(", ")
      write "**Examples:** #{allowed_values}<br/>"
    end
    write "**More information:** #{metadata["more_info"]}<br/>" if metadata["more_info"]
    write "\n"
  end
end

File.open(configuration_doc_path, "w") { |file| file << $stream.string }

required_env_vars = doc["groups"].flat_map do | group |
  group["vars"].collect do | name, _metadata |
    if name != "port"
      "env PACT_BROKER_#{name.upcase};"
    end
  end.compact
end

puts "Env vars for https://github.com/DiUS/pact_broker-docker/blob/master/container/etc/nginx/main.d/pactbroker-env.conf :"
puts required_env_vars
puts configuration_doc_path
