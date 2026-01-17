require 'pact/mock_service/cli/custom_thor'
require 'webrick/https'
require 'rack/handler/webbrick'
require 'fileutils'
require 'pact/mock_service/server/wait_for_server_up'
require 'pact/mock_service/cli/pidfile'
require 'socket'

module Pact
  module StubService
    class CLI < Pact::MockService::CLI::CustomThor

      desc 'PACT_URI ...', "Start a stub service with the given pact file(s) or directory."
      long_desc <<-DOC
        Start a stub service with the given pact file(s) or directories. Pact URIs may be local
        file or directory paths, or HTTP.
        Include any basic auth details in the URL using the format https://USERNAME:PASSWORD@URI.
        Where multiple matching interactions are found, the interactions will be sorted by
        response status, and the first one will be returned. This may lead to some non-deterministic
        behaviour. If you are having problems with this, please raise it on the pact-dev google group,
        and we can discuss some potential enhancements.
        Note that only versions 1 and 2 of the pact specification are currently fully supported.
        Pacts using the v3 format may be used, however, any matching features added in v3 will
        currently be ignored.
      DOC

      method_option :port, aliases: "-p", desc: "Port on which to run the service"
      method_option :host, aliases: "-h", desc: "Host on which to bind the service", default: 'localhost'
      method_option :log, aliases: "-l", desc: "File to which to log output"
      method_option :broker_username, aliases: "-n", desc: "Pact Broker basic auth username", :required => false
      method_option :broker_password, aliases: "-p", desc: "Pact Broker basic auth password", :required => false
      method_option :broker_token, aliases: "-k", desc: "Pact Broker bearer token (can also be set using the PACT_BROKER_TOKEN environment variable)", :required => false
      method_option :log_level, desc: "Log level. Options are DEBUG INFO WARN ERROR", default: "DEBUG"
      method_option :cors, aliases: "-o", desc: "Support browser security in tests by responding to OPTIONS requests and adding CORS headers to mocked responses"
      method_option :ssl, desc: "Use a self-signed SSL cert to run the service over HTTPS", type: :boolean, default: false
      method_option :sslcert, desc: "Specify the path to the SSL cert to use when running the service over HTTPS"
      method_option :sslkey, desc: "Specify the path to the SSL key to use when running the service over HTTPS"
      method_option :stub_pactfile_paths, hide: true
      method_option :monkeypatch, hide: true

      def service(*pact_files)
        require 'pact/mock_service/run'
        require 'pact/support/expand_file_list'

        expanded_pact_files = file_list(pact_files)
        raise Thor::Error.new("Please provide at least one pact file to load") if expanded_pact_files.empty?

        opts = Thor::CoreExt::HashWithIndifferentAccess.new
        opts.merge!(options)
        opts[:stub_pactfile_paths] = expanded_pact_files
        opts[:pactfile_write_mode] = 'none'
        MockService::Run.(opts)
      end

      desc 'version', "Show the pact-stub-service gem version"

      def version
        require 'pact/mock_service/version.rb'
        puts Pact::MockService::VERSION
      end

      default_task :service

      no_commands do
        def file_list(pact_files)
          Pact::Support::ExpandFileList.call(pact_files)
        end
      end
    end
  end
end
