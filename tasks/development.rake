
task 'pact_broker:dev:setup' do
  FileUtils.cp_r 'example', 'dev'
  gemfile_contents = File.read('dev/Gemfile')
  new_gemfile_contents = gemfile_contents.gsub(/^.*gem.*pact_broker.*$/, "gem 'pact_broker', path: '../'")
  File.open('dev/Gemfile', "w") { |file| file << new_gemfile_contents }
  bundle_install = "BUNDLE_GEMFILE=dev/Gemfile bundle install"
  puts bundle_install
  puts `#{bundle_install}`
end
