class HalRelationProxyApp

  # This hash allows us to do a dodgy "generators" implementation
  # It means we can use placeholder URLS for the relations in our consumer tests so that
  # the consumer does not need to know the actual URLs.
  PATH_REPLACEMENTS = {
    '/HAL-REL-PLACEHOLDER-INDEX-PB-LATEST-TAGGED-VERSION-Condor-production' =>
      '/pacticipants/Condor/latest-version/production',
    '/HAL-REL-PLACEHOLDER-INDEX-PB-LATEST-VERSION-Condor' =>
      '/pacticipants/Condor/latest-version',
    '/HAL-REL-PLACEHOLDER-PB-WEBHOOKS' =>
      '/webhooks',
    '/HAL-REL-PLACEHOLDER-INDEX-PB-PACTICIPANT-VERSION-Foo-26f353580936ad3b9baddb17b00e84f33c69e7cb' =>
      '/pacticipants/Foo/versions/26f353580936ad3b9baddb17b00e84f33c69e7cb'
  }

  RESPONSE_BODY_REPLACEMENTS = {
  }

  def initialize(app)
    @app = app
  end

  def call env
    env_with_modified_path = env
    PATH_REPLACEMENTS.each do | (find, replace) |
      env_with_modified_path['PATH_INFO'] = env_with_modified_path['PATH_INFO'].gsub(find, replace)
    end

    response = @app.call(env_with_modified_path)

    modified_response_body = response.last.join
    RESPONSE_BODY_REPLACEMENTS.each do | (find, replace) |
      modified_response_body = modified_response_body.gsub(find, replace)
    end

    [response[0], response[1], [modified_response_body]]
  end

end
