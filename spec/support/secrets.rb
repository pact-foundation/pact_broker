RSpec.configure do | config |
  config.around(secret_key: true) do | example |
    original_key = ENV["PACT_BROKER_SECRETS_ENCRYPTION_KEY"]
    begin
      ENV["PACT_BROKER_SECRETS_ENCRYPTION_KEY"] = "ttDJ1PnVbxGWhIe3T12UHoEfHKB4AvoxdW0JWOg98gE="
      example.call
    ensure
      ENV["PACT_BROKER_SECRETS_ENCRYPTION_KEY"] = original_key
    end
  end
end
