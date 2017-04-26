ENV['RACK_ENV'] = 'test'
RACK_ENV = 'test'

$: << File.expand_path("../../", __FILE__)
require 'rack/test'
require 'db'
require 'pact_broker/api'
require 'rspec/its'

Dir.glob("./spec/support/**/*.rb") { |file| require file  }

I18n.config.enforce_available_locales = false

RSpec.configure do | config |
  config.before :suite do
    raise "Wrong environment!!! Don't run this script!! ENV['RACK_ENV'] is #{ENV['RACK_ENV']} and RACK_ENV is #{RACK_ENV}" if ENV['RACK_ENV'] != 'test' || RACK_ENV != 'test'
    PactBroker::DB.connection = DB::PACT_BROKER_DB
  end

  config.include Rack::Test::Methods
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.include FixtureHelpers

  def app
    PactBroker::API
  end
end

class DateTime
  def self.parse *args
    begin
      super
    rescue StandardError => e
      pp args
      puts "HERE!!!! #{e.class.name} #{e.message}"
      return args[0]
    end
  end
end

require 'sequel/adapters/sqlite'
module Sequel::DeprecatedIdentifierMangling::DatasetMethods
  def fetch_rows(sql)
    execute(sql) do |result|
      i = -1
      cps = db.conversion_procs
      type_procs = result.types.map{|t| cps[base_type_name(t)]}
      cols = result.columns.map{|c| i+=1; [output_identifier(c), i, type_procs[i]]}
      puts sql
      self.columns = cols.map(&:first)
      result.each do |values|
        row = {}
        cols.each do |name,id,type_proc|
          v = values[id]
          puts "HERE!!!!" if v == "1234"
          p "#{name}: #{v}, "
          # if v == "1234"
          #   puts sql
          #   puts
          # end
          if type_proc && v
            v = type_proc.call(v)
          end
          row[name] = v
        end
        puts ""
        # pp row
        yield row
      end
    end
  end

end