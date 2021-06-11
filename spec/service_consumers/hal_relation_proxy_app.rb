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
      "/environments/16926ef3-590f-4e3f-838e-719717aa88c9/currently-deployed-versions",
    "/HAL-REL-PLACEHOLDER-PB-ENVIRONMENT-16926ef3-590f-4e3f-838e-719717aa88c9" =>
      "/environments/16926ef3-590f-4e3f-838e-719717aa88c9"
  }

  RESPONSE_BODY_REPLACEMENTS = {
  }

  def initialize(app)
    @app = app
  end

  def call env
    original_path = env["PATH_INFO"]
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
