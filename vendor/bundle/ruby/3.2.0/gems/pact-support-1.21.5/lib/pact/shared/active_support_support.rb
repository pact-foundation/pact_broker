# The support you need when you use ActiveSupport

module Pact
  module ActiveSupportSupport
    extend self

    def fix_all_the_things thing
      if defined?(ActiveSupport)
        if thing.is_a?(Regexp)
          fix_regexp(thing)
        elsif thing.is_a?(Array)
          thing.collect{ | it | fix_all_the_things it }
        elsif thing.is_a?(Hash)
          thing.each_with_object({}) { | (k, v), new_hash | new_hash[k] = fix_all_the_things(v) }
        elsif thing.is_a?(Pact::Term)
          # matcher Regexp is fixed in its own as_json method
          thing
        elsif thing.class.name.start_with?("Pact")
          warn_about_regexp(thing)
          thing
        else
          thing
        end
      else
        thing
      end
    end

    # ActiveSupport JSON overwrites (i.e. TRAMPLES) the json methods of the Regexp class directly
    # (beneath its destructive hooves of destruction).
    # This does not seem to be able to be undone without affecting the JSON serialisation in the
    # calling project, so the best way I've found to fix this issue is to reattach the
    # original as_json to the Regexp instances in the ConsumerContract before we write them to the
    # pact file. If anyone can find a better way, please submit a pull request ASAP!
    def fix_regexp regexp
      {:json_class => 'Regexp', "o" => regexp.options, "s" => regexp.source }
    end

    # Having Active Support JSON loaded somehow kills the formatting of pretty_generate for objects.
    # Don't ask me why, but it still seems to work for hashes, so the hacky work around is to
    # reparse the generated JSON into a hash and pretty_generate that... sigh...
    # Oh ActiveSupport, why....
    def fix_json_formatting json
      if json =~ /\{".*?":"/
        json = JSON.pretty_generate(JSON.parse(json, create_additions: false))
      else
        json
      end
      fix_empty_hash_and_array json
    end

    def remove_unicode json
      json.gsub(/\\u([0-9A-Za-z]{4})/) {|s| [$1.to_i(16)].pack("U")}
    end

    def warn_about_regexp(thing)
      thing.instance_variables.each do | iv_name |
        iv = thing.instance_variable_get(iv_name)
        if iv.is_a?(Regexp)
          require 'pact/configuration'
          Pact.configuration.error_stream.puts("WARN: Instance variable #{iv_name} for class #{thing.class.name} is a Regexp and isn't been serialized properly. Please raise an issue at https://github.com/pact-foundation/pact-support/issues/new.")
        end
      end
    end

    private

    def fix_empty_hash_and_array json
      json
        .gsub(/({\s*})(?=,?$)/, "{\n        }")
        .gsub(/\[\s*\](?=,?$)/, "[\n        ]")
    end
  end
end
