# frozen_string_literal: true

module Faraday
  # Adds the ability to retry a request based on settings and errors that have occurred.
  module Retryable
    def with_retries(env:, options:, retries:, body:, errmatch:)
      yield
    rescue errmatch => e
      exhausted_retries(options, env, e) if retries_zero?(retries, env, e)

      if retries.positive? && retry_request?(env, e)
        retries -= 1
        rewind_files(body)
        if (sleep_amount = calculate_sleep_amount(retries + 1, env))
          options.retry_block.call(
            env: env,
            options: options,
            retry_count: options.max - (retries + 1),
            exception: e,
            will_retry_in: sleep_amount
          )
          sleep sleep_amount
          retry
        end
      end

      raise unless e.is_a?(Faraday::RetriableResponse)

      e.response
    end

    private

    def retries_zero?(retries, env, exception)
      retries.zero? && retry_request?(env, exception)
    end

    def exhausted_retries(options, env, exception)
      options.exhausted_retries_block.call(
        env: env,
        exception: exception,
        options: options
      )
    end
  end
end
