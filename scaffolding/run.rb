require 'pact_broker/string_refinements'
require 'pact_broker/project_root'
require 'date'
require 'erb'
require 'pathname'

using PactBroker::StringRefinements

MODEL_CLASS_FULL_NAME = "PactBroker::Foos::Foo"

TEMPLATE_DIR = Pathname.new(File.join(__dir__, "templates"))
MIGRATIONS_DIR = PactBroker.project_root.join("db", "migrations").tap { |it| puts it }
LIB_DIR = PactBroker.project_root.join("lib")

def model_full_class_name
  MODEL_CLASS_FULL_NAME
end

def today
  DateTime.now.strftime('%Y%m%d')
end

def migration_path
  MIGRATIONS_DIR.join(today + "_create_#{table_name}_table.rb")
end

def model_class_name
  model_full_class_name.split("::").last
end

def model_top_module
  model_full_class_name.split("::").first
end

def model_secondary_module
  model_full_class_name.split("::")[1]
end

def model_instance_name
  model_class_name.snakecase
end

def policy_name
  model_secondary_module.snakecase + "::" + model_class_name.snakecase
end

def service_instance_name
  model_class_name.snakecase + "_service"
end

def table_name
  model_class_name.snakecase
end

def model_class_name_snakecase
  model_class_name.snakecase
end

def migration_template_path
  File.join(__dir__, "templates", "migration.erb")
end

def generate_migration_file
  generate_file(migration_template_path, migration_path)
end

def model_path
  LIB_DIR.join(*model_full_class_name.split("::").collect(&:snakecase)).to_s.chomp("/") + ".rb"
end

def generate_model_file
  generate_file(TEMPLATE_DIR.join("model.erb"), model_path)
end

def resource_path
  LIB_DIR.join(model_top_module.snakecase, "api", "resources", model_class_name_snakecase + ".rb").tap { |it| puts it }
end

def generate_resource_file
  generate_file(TEMPLATE_DIR.join("resource.erb"), resource_path)
end

def decorator_instance_name
  model_class_name_snakecase + "_decorator"
end

def generate_file(template, destination)
  puts "Generating file #{destination}"
  file_content = ERB.new(File.read(template)).result(binding).tap { |it| puts it }
  FileUtils.mkdir_p(File.dirname(destination))
  File.open(destination, "w") { |file| file << file_content }
end

generate_migration_file
generate_model_file
generate_resource_file
