class HalRelationProxyApp

  # This hash allows us to do a dodgy "generators" implementation
  # It means we can use placeholder URLS for the relations in our consumer tests so that
  # the consumer does not need to know the actual URLs.
  PATH_REPLACEMENTS = {
    '/HAL-REL-PLACEHOLDER-INDEX-PB-LATEST-TAGGED-VERSION-Condor-production' =>
      '/pacticipants/Condor/latest-version/production',
    '/HAL-REL-PLACEHOLDER-INDEX-PB-LATEST-VERSION-Condor' =>
      '/pacticipants/Condor/latest-version'
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
