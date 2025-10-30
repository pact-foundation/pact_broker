class HalRelationProxyApp

  # This hash allows us to do a dodgy "generators" implementation
  # It means we can use placeholder URLS for the relations in our consumer tests so that
  # the consumer does not need to know the actual URLs.
  PATH_REPLACEMENTS = {
    "/HAL-REL-PLACEHOLDER-INDEX-PB-LATEST-TAGGED-VERSION-Condor-production" =>
      "/pacticipants/Condor/latest-version/production",
    "/HAL-REL-PLACEHOLDER-INDEX-PB-LATEST-VERSION-Condor" =>
      "/pacticipants/Condor/latest-version",
    "/HAL-REL-PLACEHOLDER-PB-WEBHOOKS" =>
      "/webhooks",
    "/HAL-REL-PLACEHOLDER-INDEX-PB-PACTICIPANT-VERSION-Foo-26f353580936ad3b9baddb17b00e84f33c69e7cb" =>
      "/pacticipants/Foo/versions/26f353580936ad3b9baddb17b00e84f33c69e7cb",
    "/HAL-REL-PLACEHOLDER-PB-ENVIRONMENTS" =>
      "/environments",
    "/HAL-REL-PLACEHOLDER-PB-PACTICIPANT-VERSION-Foo-5556b8149bf8bac76bc30f50a8a2dd4c22c85f30" =>
      "/pacticipants/Foo/versions/5556b8149bf8bac76bc30f50a8a2dd4c22c85f30",
    "/HAL-REL-PLACEHOLDER-PB-RECORD-DEPLOYMENT-FOO-5556B8149BF8BAC76BC30F50A8A2DD4C22C85F30-TEST" =>
      "/pacticipants/Foo/versions/5556b8149bf8bac76bc30f50a8a2dd4c22c85f30/deployed-versions/environment/cb632df3-0a0d-4227-aac3-60114dd36479",
    "/HAL-REL-PLACEHOLDER-PB-PUBLISH-CONTRACTS" =>
      "/contracts/publish",
    "/HAL-REL-PLACEHOLDER-PB-RECORD-RELEASE-FOO-5556B8149BF8BAC76BC30F50A8A2DD4C22C85F30-TEST" =>
      "/pacticipants/Foo/versions/5556b8149bf8bac76bc30f50a8a2dd4c22c85f30/deployed-versions/environment/cb632df3-0a0d-4227-aac3-60114dd36479",
    "/PLACEHOLDER-DEPLOYED-VERSION-ff3adecf-cfc5-4653-a4e3-f1861092f8e0" =>
      "/deployed-versions/ff3adecf-cfc5-4653-a4e3-f1861092f8e0",
    "/PLACEHOLDER-ENVIRONMENT-CURRENTLY-DEPLOYED-16926ef3-590f-4e3f-838e-719717aa88c9" =>
      "/environments/16926ef3-590f-4e3f-838e-719717aa88c9/deployed-versions/currently-deployed",
    "/HAL-REL-PLACEHOLDER-PB-ENVIRONMENT-16926ef3-590f-4e3f-838e-719717aa88c9" =>
      "/environments/16926ef3-590f-4e3f-838e-719717aa88c9",
    "/HAL-REL-PLACEHOLDER-PB-PACTICIPANT-BRANCH-Foo-main" =>
      "/pacticipants/Foo/branches/main"
  }

  RESPONSE_BODY_REPLACEMENTS = {
  }

  # query strings sent from the v2 ruby pact, is re-ordered by the rust app?
  # so we need to re-order them here to match the expected query string
  # PASS
  # curl 'localhost:9292/matrix?ignore%5B%5D%5Bpacticipant%5D=Foo&ignore%5B%5D%5Bversion%5D=3.4.5&latestby=cvpv&q%5B%5D%5Bpacticipant%5D=Bar&q%5B%5D%5Bversion%5D=4.5.6&q%5B%5D%5Bpacticipant%5D=Foo&q%5B%5D%5Btag%5D=prod' | jq .
  # FAIL
  # curl 'localhost:9292/matrix?ignore%5B%5D%5Bpacticipant%5D=Foo&ignore%5B%5D%5Bversion%5D=3.4.5&latestby=cvpv&q%5B%5D%5Bpacticipant%5D=Bar&q%5B%5D%5Bpacticipant%5D=Foo&q%5B%5D%5Btag%5D=prod&q%5B%5D%5Bversion%5D=4.5.6' | jq .
  QUERY_STRING_REPLACEMENTS = {
    # pact-ruby-v2 pact (as v2) verified by pact-ruby-v2
    "ignore%5B%5D%5Bpacticipant%5D=Foo&ignore%5B%5D%5Bversion%5D=3.4.5&latestby=cvpv&q%5B%5D%5Bpacticipant%5D=Bar&q%5B%5D%5Bpacticipant%5D=Foo&q%5B%5D%5Btag%5D=prod&q%5B%5D%5Bversion%5D=4.5.6" =>
      "q%5B%5D%5Bpacticipant%5D=Bar&q%5B%5D%5Bversion%5D=4.5.6&q%5B%5D%5Bpacticipant%5D=Foo&q%5B%5D%5Btag%5D=prod&latestby=cvpv&ignore%5B%5D%5Bpacticipant%5D=Foo&ignore%5B%5D%5Bversion%5D=3.4.5",
    # pact-ruby-v2 pact (as v2) verified by pact-ruby-v1
    "ignore[][pacticipant]=Foo&ignore[][version]=3%2e4%2e5&latestby=cvpv&q[][pacticipant]=Bar&q[][pacticipant]=Foo&q[][tag]=prod&q[][version]=4%2e5%2e6" =>
      "q%5B%5D%5Bpacticipant%5D=Bar&q%5B%5D%5Bversion%5D=4.5.6&q%5B%5D%5Bpacticipant%5D=Foo&q%5B%5D%5Btag%5D=prod&latestby=cvpv&ignore%5B%5D%5Bpacticipant%5D=Foo&ignore%5B%5D%5Bversion%5D=3.4.5",

    # pact-ruby-v2 pact (as v2) verified by pact-ruby-v2
    "latestby=cvpv&q%5B%5D%5Bpacticipant%5D=Foo&q%5B%5D%5Bpacticipant%5D=Bar&q%5B%5D%5Bversion%5D=1.2.3&q%5B%5D%5Bversion%5D=4.5.6" =>
      "q%5B%5D%5Bpacticipant%5D=Foo&q%5B%5D%5Bversion%5D=1.2.3&q%5B%5D%5Bpacticipant%5D=Bar&q%5B%5D%5Bversion%5D=4.5.6&latestby=cvpv",
    # pact-ruby-v2 pact (as v2) verified by pact-ruby-v1
    # "latestby=cvpv&q[][pacticipant]=Foo&q[][pacticipant]=Bar&q[][version]=1%2e2%2e3&q[][version]=4%2e5%2e6" =>
    #   "q%5B%5D%5Bpacticipant%5D=Foo&q%5B%5D%5Bversion%5D=1.2.3&q%5B%5D%5Bpacticipant%5D=Bar&q%5B%5D%5Bversion%5D=4.5.6&latestby=cvpv",

    # pact-ruby-v2 pact (as v2) verified by pact-ruby-v2
    "latestby=cvpv&q%5B%5D%5Bpacticipant%5D=Foo+Thing&q%5B%5D%5Bpacticipant%5D=Bar&q%5B%5D%5Bversion%5D=1.2.3&q%5B%5D%5Bversion%5D=4.5.6" =>
      "q%5B%5D%5Bpacticipant%5D=Foo%20Thing&q%5B%5D%5Bversion%5D=1.2.3&q%5B%5D%5Bpacticipant%5D=Bar&q%5B%5D%5Bversion%5D=4.5.6&latestby=cvpv",
    # pact-ruby-v2 pact (as v2) verified by pact-ruby-v1
    # "latestby=cvpv&q[][pacticipant]=Foo+Thing&q[][pacticipant]=Bar&q[][version]=1%2e2%2e3&q[][version]=4%2e5%2e6" =>
    #   "q%5B%5D%5Bpacticipant%5D=Foo%20Thing&q%5B%5D%5Bversion%5D=1.2.3&q%5B%5D%5Bpacticipant%5D=Bar&q%5B%5D%5Bversion%5D=4.5.6&latestby=cvpv",

    # pact-ruby-v2 pact (as v2) verified by pact-ruby-v2
    "latestby=cvpv&q%5B%5D%5Bpacticipant%5D=Foo&q%5B%5D%5Bpacticipant%5D=Bar&q%5B%5D%5Bversion%5D=1.2.3&q%5B%5D%5Bversion%5D=9.9.9" =>
      "q%5B%5D%5Bpacticipant%5D=Foo&q%5B%5D%5Bversion%5D=1.2.3&q%5B%5D%5Bpacticipant%5D=Bar&q%5B%5D%5Bversion%5D=9.9.9&latestby=cvpv",
    # pact-ruby-v2 pact (as v2) verified by pact-ruby-v1
    # "latestby=cvpv&q[][pacticipant]=Foo&q[][pacticipant]=Bar&q[][version]=1%2e2%2e3&q[][version]=9%2e9%2e9" =>
    #   "q%5B%5D%5Bpacticipant%5D=Foo&q%5B%5D%5Bversion%5D=1.2.3&q%5B%5D%5Bpacticipant%5D=Bar&q%5B%5D%5Bversion%5D=9.9.9&latestby=cvpv",

    # pact-ruby-v2 pact (as v2) verified by pact-ruby-v2 
    "latestby=cvpv&q%5B%5D%5Blatest%5D=true&q%5B%5D%5Bpacticipant%5D=Foo&q%5B%5D%5Bpacticipant%5D=Bar&q%5B%5D%5Btag%5D=prod&q%5B%5D%5Bversion%5D=1.2.3" => 
      "q%5B%5D%5Bpacticipant%5D=Foo&q%5B%5D%5Bversion%5D=1.2.3&q%5B%5D%5Bpacticipant%5D=Bar&q%5B%5D%5Blatest%5D=true&q%5B%5D%5Btag%5D=prod&latestby=cvpv",
    # pact-ruby-v2 pact (as v2) verified by pact-ruby-v1
    # "latestby=cvpv&q[][latest]=true&q[][pacticipant]=Foo&q[][pacticipant]=Bar&q[][tag]=prod&q[][version]=1%2e2%2e3" => 
    #   "q%5B%5D%5Bpacticipant%5D=Foo&q%5B%5D%5Bversion%5D=1.2.3&q%5B%5D%5Bpacticipant%5D=Bar&q%5B%5D%5Blatest%5D=true&q%5B%5D%5Btag%5D=prod&latestby=cvpv",

    # pact-ruby-v2 pact (as v2) verified by pact-ruby-v2
    "latestby=cvpv&q%5B%5D%5Blatest%5D=true&q%5B%5D%5Bpacticipant%5D=Foo&q%5B%5D%5Bpacticipant%5D=Bar&q%5B%5D%5Bversion%5D=1.2.4" => 
      "q%5B%5D%5Bpacticipant%5D=Foo&q%5B%5D%5Bversion%5D=1.2.4&q%5B%5D%5Bpacticipant%5D=Bar&q%5B%5D%5Blatest%5D=true&latestby=cvpv",
    # pact-ruby-v2 pact (as v2) verified by pact-ruby-v1
    # "latestby=cvpv&q[][latest]=true&q[][pacticipant]=Foo&q[][pacticipant]=Bar&q[][version]=1%2e2%2e4" => 
    #   "q%5B%5D%5Bpacticipant%5D=Foo&q%5B%5D%5Bversion%5D=1.2.4&q%5B%5D%5Bpacticipant%5D=Bar&q%5B%5D%5Blatest%5D=true&latestby=cvpv",
    # pact-broker-cli rust rewrite (unordered query params)
   "latestby=cvpv&q[][latest]=true&q[][pacticipant]=Foo&q[][tag]=prod&q[][version]=1%2e2%2e3&q[][pacticipant]=Bar" => "q[][pacticipant]=Foo&q[][version]=1%2e2%2e3&q[][pacticipant]=Bar&q[][latest]=true&q[][tag]=prod&latestby=cvpv",
   "latestby=cvpv&q[][latest]=true&q[][pacticipant]=Foo&q[][version]=1%2e2%2e4&q[][pacticipant]=Bar" => "q[][pacticipant]=Foo&q[][version]=1%2e2%2e4&q[][pacticipant]=Bar&q[][latest]=true&latestby=cvpv",
   "latestby=cvpv&q[][pacticipant]=Foo+Thing&q[][pacticipant]=Bar&q[][version]=1%2e2%2e3&q[][version]=4%2e5%2e6" => "q[][pacticipant]=Foo+Thing&q[][version]=1%2e2%2e3&q[][pacticipant]=Bar&q[][version]=4%2e5%2e6&latestby=cvpv",
   "latestby=cvpv&q[][pacticipant]=Foo&q[][pacticipant]=Bar&q[][version]=1%2e2%2e3&q[][version]=4%2e5%2e6" => "q[][pacticipant]=Foo&q[][version]=1%2e2%2e3&q[][pacticipant]=Bar&q[][version]=4%2e5%2e6&latestby=cvpv",
   "latestby=cvpv&q[][latest]=true&q[][pacticipant]=Foo&q[][pacticipant]=Bar&q[][tag]=prod&q[][version]=1%2e2%2e3" => "q[][pacticipant]=Foo&q[][version]=1%2e2%2e3&q[][pacticipant]=Bar&q[][latest]=true&q[][tag]=prod&latestby=cvpv",
   "latestby=cvpv&q[][latest]=true&q[][pacticipant]=Foo&q[][pacticipant]=Bar&q[][version]=1%2e2%2e4" => "q[][pacticipant]=Foo&q[][version]=1%2e2%2e4&q[][pacticipant]=Bar&q[][latest]=true&latestby=cvpv",
   "latestby=cvpv&q[][pacticipant]=Foo&q[][pacticipant]=Bar&q[][version]=1%2e2%2e3&q[][version]=9%2e9%2e9" => "q[][pacticipant]=Foo&q[][version]=1%2e2%2e3&q[][pacticipant]=Bar&q[][version]=9%2e9%2e9&latestby=cvpv"
  }

  def initialize(app)
    @app = app
  end

  def call env
    original_path = env["PATH_INFO"]
    original_query = env["QUERY_STRING"]

    QUERY_STRING_REPLACEMENTS.each do | (find, replace) |
      env["QUERY_STRING"] = env["QUERY_STRING"].gsub(find, replace)
    end

    if env["QUERY_STRING"] != original_query
      puts "Modified query string: #{env["QUERY_STRING"]}"
    end

    env_with_modified_path = env
    PATH_REPLACEMENTS.each do | (find, replace) |
      env_with_modified_path["PATH_INFO"] = env_with_modified_path["PATH_INFO"].gsub(find, replace)
    end

    if env_with_modified_path["PATH_INFO"] != original_path
      puts "Redirected to: #{env_with_modified_path["PATH_INFO"]}"
    end

    response = @app.call(env_with_modified_path)

    modified_response_body = response.last.join
    RESPONSE_BODY_REPLACEMENTS.each do | (find, replace) |
      modified_response_body = modified_response_body.gsub(find, replace)
    end

    [response[0], response[1], [modified_response_body]]
  end

end
