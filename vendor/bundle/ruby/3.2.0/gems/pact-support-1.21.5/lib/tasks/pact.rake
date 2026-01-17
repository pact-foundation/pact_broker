
namespace :pact do

  desc "Verifies the pact files configured in the pact_helper.rb against this service provider."
  task :verify do

    require 'pact/tasks/task_helper'

    include Pact::TaskHelper

    handle_verification_failure do
      execute_pact_verify
    end
  end

  desc "Verifies the pact at the given URI against this service provider."
  task 'verify:at', :pact_uri do | t, args |
    require 'rainbow'
    require 'pact/tasks/task_helper'

    include Pact::TaskHelper

    abort(Rainbow("Please provide a pact URI. eg. rake pact:verify:at[../my-consumer/spec/pacts/my_consumer-my_provider.json]").red) unless args[:pact_uri]
    handle_verification_failure do
      execute_pact_verify args[:pact_uri]
    end
  end

end
