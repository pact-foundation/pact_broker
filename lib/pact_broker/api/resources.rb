require 'reform'
require 'reform/form/dry'

Reform::Form.class_eval do
  feature Reform::Form::Dry
end

Dir.glob(File.expand_path(File.join(__FILE__, "..", "resources", "*.rb"))) do |file|
  require file
end
