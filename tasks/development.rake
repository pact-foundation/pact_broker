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
task :'pact_broker:routes', [:search_term] do | _t, args |
  project_root = File.absolute_path(File.join(__dir__, "..", "..", ".."))
  $LOAD_PATH << File.join(project_root,"app_shared","lib")

  search_term = args[:search_term]
  puts "Listing Pact Broker routes containing the term '#{search_term}'" if search_term
  require "tempfile"
  require "sequel"
  require "pact_broker"
  require "pact_broker/project_root"
  require "pathname"

  Tempfile.create("pact_broker_routes") do |f|
    CONNECTION = Sequel.connect({ adapter: "sqlite", database: f.path, encoding: "utf8", sql_log_level: :debug })

    require "pact_broker/db"
    PactBroker::DB.run_migrations(CONNECTION)

    require "pact_broker/api"
    require "webmachine/describe_routes"

    routes = Webmachine::DescribeRoutes.call([PactBroker::API.application], search_term: search_term)

    routes.each do | route |
      puts ""
      puts "#{route.path}"
      puts "      allowed_methods: #{route.allowed_methods.join(", ")}"
      puts "      class: #{route.resource_class}"
      puts "            location: #{route.resource_class_location}"
      if route[:schemas]
        puts "      schemas:"
        route[:schemas].each do | schema |
          puts "            class: #{schema[:class]}"
          puts "                   location: #{schema[:location]}"

        end
      end
    end
  end
end
