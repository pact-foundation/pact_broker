require 'simplecov'

SimpleCov.command_name ENV['SIMPLECOV_COMMAND_NAME'] if ENV['SIMPLECOV_COMMAND_NAME']
SimpleCov.start do
  add_filter '/db/'
  add_filter '/example/'
  add_filter '/spec/'
  add_filter '/tasks/'
  add_filter '/script/'
end
