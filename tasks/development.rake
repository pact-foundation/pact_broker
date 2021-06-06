desc "Set up a dev instance of the Pact Broker"
task "pact_broker:dev:setup" do
  puts "Copying example directory"
  FileUtils.cp_r "example", "dev"
  gemfile_contents = File.read("dev/Gemfile")


  puts "Changing source of pact_broker gem from rubygems.org to local file system"
  new_gemfile_contents = gemfile_contents.gsub(/^.*gem.*pact_broker.*$/, "gem 'pact_broker', path: '../'")
  File.open("dev/Gemfile", "w") { |file| file << new_gemfile_contents }

  Dir.chdir("dev") do
    Bundler.with_clean_env do
      puts "Executing bundle update"
      puts `bundle update`
    end
  end
end

desc "List the Pact Broker API routes"
task "pact_broker:routes", [:search_term] do | _, args |
  puts "Listing routes containing the term '#{args[:search_term]}'" if args[:search_term]
  require "tempfile"
  require "sequel"
  require "pact_broker"
  require "pact_broker/project_root"

  Tempfile.create("pact_broker_routes") do |f|
    CONNECTION = Sequel.connect({ adapter: "sqlite", database: f.path, encoding: "utf8", sql_log_level: :debug })

    require "pact_broker/db"
    PactBroker::DB.run_migrations(CONNECTION)

    require "pact_broker/api"

    routes_debugging = PactBroker::API.application.routes.collect do | route |
      ["/" + route.path_spec.collect{ |part| part.is_a?(Symbol) ? ":#{part}" : part  }.join("/"), route.resource]
    end

    if args[:search_term]
      routes_debugging = routes_debugging.select{ |(route, _)| route.include?(args[:search_term]) }
    end

    routes_debugging.sort_by(&:first).each do | (path, resource_class) |
      puts ""
      puts "#{path}"
      puts "      class: #{resource_class}"
      puts "      location: #{resource_class.instance_method(:allowed_methods).source_location.first.gsub(PactBroker.project_root.to_s + "/", "")}"
    end
  end
end
