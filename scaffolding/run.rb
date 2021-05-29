#!/usr/bin/env ruby

require 'pact_broker/string_refinements'
require 'pact_broker/project_root'
require 'date'
require 'erb'
require 'pathname'
require 'fileutils'

using PactBroker::StringRefinements

MODEL_CLASS_FULL_NAME = "PactBroker::Foos::Foo"
DRY_RUN = true

TEMPLATE_DIR = Pathname.new(File.join(__dir__, "templates"))
MIGRATIONS_DIR = PactBroker.project_root.join("db", "migrations")
LIB_DIR = PactBroker.project_root.join("lib")
SPEC_DIR = PactBroker.project_root.join("spec", "lib")

def model_full_class_name
  MODEL_CLASS_FULL_NAME
end

def today
  DateTime.now.strftime('%Y%m%d')
end

def require_path_prefix
  model_top_module.snakecase
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

# Resource

def resource_top_module
  model_top_module
end

def resource_class_name
  model_class_name
end

def resource_class_full_name
  "#{resource_top_module}::Api::Resources::#{resource_class_name}"
end

def resource_url_path
  model_class_name_snakecase.tr("_", "-") + "s"
end

# Decorator

def decorator_class_name
  model_class_name + "Decorator"
end

def decorator_full_class_name
  "#{resource_top_module}::Api::Decorators::#{resource_class_name}Decorator"
end

def decorator_instance_name
  model_class_name_snakecase + "_decorator"
end

# Service

def service_class_full_name
  model_full_class_name.split("::")[0..1].join("::") + "::Service"
end

def service_class_name
  service_class_full_name.split("::").last
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

# Repository

def repository_class_full_name
  model_full_class_name.split("::")[0..1].join("::") + "::Repository"
end

def repository_class_name
  repository_class_full_name.split("::").last
end

def repository_instance_name
  model_class_name.snakecase + "_repository"
end

# Table

def table_name
  model_class_name.snakecase + "s"
end

def model_class_name_snakecase
  model_class_name.snakecase
end

# File paths

def migration_template_path
  File.join(__dir__, "templates", "migration.erb")
end

def model_path
  LIB_DIR.join(*model_full_class_name.split("::").collect(&:snakecase)).to_s.chomp("/") + ".rb"
end

def resource_path
  LIB_DIR.join(model_top_module.snakecase, "api", "resources", model_class_name_snakecase + ".rb")
end

def resource_spec_path
  resource_path.to_s.gsub(LIB_DIR.to_s, SPEC_DIR.to_s).gsub(".rb", "_spec.rb")
end

def resource_require_path
  Pathname.new(resource_path).relative_path_from(LIB_DIR).to_s.chomp(".rb")
end

def decorator_path
  LIB_DIR.join(model_top_module.snakecase, "api", "decorators", model_class_name_snakecase + "_decorator.rb")
end

def decorator_require_path
  Pathname.new(decorator_path).relative_path_from(LIB_DIR).to_s.chomp(".rb")
end

def service_path
  LIB_DIR.join(*service_class_full_name.split("::").collect(&:snakecase)).to_s.chomp("/") + ".rb"
end

def service_require_path
  Pathname.new(service_path).relative_path_from(LIB_DIR).to_s.chomp(".rb")
end

def service_spec_path
  service_path.to_s.gsub(LIB_DIR.to_s, SPEC_DIR.to_s).gsub(".rb", "_spec.rb")
end

def repository_path
  LIB_DIR.join(*repository_class_full_name.split("::").collect(&:snakecase)).to_s.chomp("/") + ".rb"
end

def repository_require_path
  Pathname.new(repository_path).relative_path_from(LIB_DIR).to_s.chomp(".rb")
end

def repository_spec_path
  repository_path.to_s.gsub(LIB_DIR.to_s, SPEC_DIR.to_s).gsub(".rb", "_spec.rb")
end

# Generate

def generate_migration_file
  generate_file(migration_template_path, migration_path)
end

def generate_model_file
  generate_file(TEMPLATE_DIR.join("model.erb"), model_path)
end

def generate_resource_file
  generate_file(TEMPLATE_DIR.join("resource.erb"), resource_path)
end

def generate_resource_spec
  generate_file(TEMPLATE_DIR.join("resource_spec.rb.erb"), resource_spec_path)
end

def generate_decorator_file
  generate_file(TEMPLATE_DIR.join("decorator.rb.erb"), decorator_path)
end

def generate_service_file
  generate_file(TEMPLATE_DIR.join("service.rb.erb"), service_path)
end

def generate_service_spec_file
  generate_file(TEMPLATE_DIR.join("service_spec.rb.erb"), service_spec_path)
end

def generate_repository_file
  generate_file(TEMPLATE_DIR.join("repository.rb.erb"), repository_path)
end

def generate_repository_spec_file
  generate_file(TEMPLATE_DIR.join("repository_spec.rb.erb"), repository_spec_path)
end


def generate_file(template, destination)
  puts "Generating file #{destination}"
  file_content = ERB.new(File.read(template)).result(binding).tap { |it| puts it }
  if !DRY_RUN
    FileUtils.mkdir_p(File.dirname(destination))
    if File.exist?(destination)
      raise "File #{destination} already exists"
    else
      File.open(destination, "w") { |file| file << file_content }
    end
  end
end

generate_migration_file
generate_model_file
generate_resource_file
generate_resource_spec
generate_decorator_file
generate_service_file
generate_service_spec_file
generate_repository_file
generate_repository_spec_file

puts "THIS WAS A DRY RUN. Set DRY_RUN = true to generate the files." if DRY_RUN
