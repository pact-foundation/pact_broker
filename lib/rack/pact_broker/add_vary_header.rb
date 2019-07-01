=begin

  This header should fix the situation where using the back button shows the json/csv instead of the html.

  > Unlike intermediary caches (such as CDNs), browsers typically do not implement the capability to
  store multiple variations per URL. The rationale for this is that the things we typically use Vary
  for (mainly Accept-Encoding and Accept-Language) do not change frequently within the context of a
  single user. Accept-Encoding might (but probably doesn’t) change upon a browser upgrade, and
  Accept-Language would most likely only change if you edit your operating system’s language locale
  settings. It also happens to be a lot easier to implement Vary in this way, although some specification
  authors believe this was a mistake.

  > It’s no great loss most of the time for a browser to store only one variation, but it is important
  that we don’t accidentally use a variation that isn’t valid anymore if the “varied on” data does
  happen to change.

  > The compromise is to treat Vary as a validator, not a key. Browsers compute cache keys in the normal
  way (essentially, using the URL), and then if they score a hit, they check that the request satisfies any
  ry rules that are baked into the cached response. If it doesn’t, then the browser treats the request as a
  iss on the cache, and it moves on to the next layer of cache or out to the network. When a fresh response
  is received, it will then overwrite the cached version, even though it’s technically a different variation.

  https://www.smashingmagazine.com/2017/11/understanding-vary-header/
=end

module Rack
  module PactBroker
    class AddVaryHeader
      def initialize app
        @app = app
      end

      def call(env)
        status, headers, body = @app.call(env)
        [status, { "Vary" => "Accept" }.merge(headers || {}), body]
      end
    end
  end
end
