require "sequel/annotate"

module PactBroker
  class Annotate
    def self.call
      annotation_configuration.each_pair do | klass, path |
        begin
          puts "Annotating #{klass}"
          sa = Sequel::Annotate.new(klass)
          sa.annotate(path)
        rescue StandardError => e
          puts "Error annnotating #{klass} - #{e.message}\n#{e.backtrace.join("\n")}"
        end
      end
    end

    def self.annotation_configuration
      sequel_domain_classes.each_with_object({}) do | klass, configs |
        file_path = file_path_for_class(klass)
        if File.exist?(file_path)
          if klass.db.table_exists?(klass.table_name)
            configs[klass] = file_path
          else
            puts "Skipping annotation for #{klass} as the configured table_name '#{klass.table_name}' is not a real table"
          end
        else
          puts "Skipping annotation for #{klass} as the generated file path #{file_path} does not exist"
        end
      end
    end

    def self.sequel_domain_classes

      Dir.chdir("lib") { Dir.glob("**/*.rb") }.sort.each do | path |
        require path
      end

      ObjectSpace
        .each_object(::Class).select {|klass| klass < ::Sequel::Model }
        .select{ |klass| klass.name && klass.name.start_with?("PactBroker::") }
        .sort{ | c1, c2| c1.name <=> c2.name }
    end

    def self.file_path_for_class klass
      "lib/" + klass.name.gsub("::", "/").gsub(/([a-z])([A-Z])/) {|match| match[0] + "_" + match[1].downcase }.downcase + ".rb"
    end
  end
end
