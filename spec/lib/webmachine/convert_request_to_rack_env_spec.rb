require 'webmachine/convert_request_to_rack_env'
require 'webmachine/request'

module Webmachine
  describe ConvertRequestToRackEnv do

    let(:rack_env) do
      {
        "rack.input" => StringIO.new('foo'),
        "REQUEST_METHOD" => "POST",
        "SERVER_NAME" => "example.org",
        "SERVER_PORT" => "80",
        "QUERY_STRING" => "",
        "PATH_INFO" => "/foo",
        "rack.url_scheme" => "http",
        "SCRIPT_NAME" => "",
        "CONTENT_LENGTH" => "0",
        "HTTP_HOST" => "example.org",
        "CONTENT_TYPE" => "application/x-www-form-urlencoded",
        "HTTP_AUTHORIZATION"  =>  "auth",
        "HTTP_TOKEN" => "foo"
      }
    end

    let(:expected_rack_env) do
      {
        "REQUEST_METHOD" => "POST",
        "SERVER_NAME" => "example.org",
        "SERVER_PORT" => "80",
        "QUERY_STRING" => "",
        "PATH_INFO" => "/foo",
        "rack.url_scheme" => "http",
        "SCRIPT_NAME" => "",
        "CONTENT_LENGTH" => "0",
        "HTTP_HOST" => "example.org",
        "CONTENT_TYPE" => "application/x-www-form-urlencoded",
        "HTTP_AUTHORIZATION" => "[Filtered]",
        "HTTP_TOKEN" => "[Filtered]"
      }
    end

    let(:headers) do
      Webmachine::Headers.from_cgi(rack_env)
    end

    let(:rack_req) { ::Rack::Request.new(rack_env) }
    let(:webmachine_request) do
      Webmachine::Request.new(rack_req.request_method,
                              rack_req.url,
                              headers,
                              Webmachine::Adapters::Rack::RequestBody.new(rack_req),
                              nil,
                              nil
                             )
    end

    subject { ConvertRequestToRackEnv.call(webmachine_request) }

    describe ".call" do
      it "returns a rack env hash created from the Webmachine::Request" do
        actual_env = subject
        actual_rack_input = actual_env.delete('rack.input')
        expect(subject).to eq expected_rack_env
        expect(actual_rack_input.string).to eq 'foo'
      end
    end
  end
end
