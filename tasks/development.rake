
desc 'Set up a dev instance of the Pact Broker'
task 'pact_broker:dev:setup' do
  puts "Copying example directory"
  FileUtils.cp_r 'example', 'dev'
  gemfile_contents = File.read('dev/Gemfile')


  puts "Changing source of pact_broker gem from rubygems.org to local file system"
  new_gemfile_contents = gemfile_contents.gsub(/^.*gem.*pact_broker.*$/, "gem 'pact_broker', path: '../'")
  File.open('dev/Gemfile', "w") { |file| file << new_gemfile_contents }

  Dir.chdir("dev") do
    Bundler.with_clean_env do
      puts "Executing bundle install"
      puts `bundle install`
    end
  end
end
