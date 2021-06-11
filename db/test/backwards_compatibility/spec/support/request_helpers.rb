module RequestHelpers
  def wait_for_server_to_start
    unless ENV["OK"]
      retries = 0
      begin
        get "/"
        ENV["OK"] = "true"
      rescue Errno::ECONNREFUSED => error
        if retries < 10
          retries += 1
          sleep 1
          retry
        else
          raise error
        end
      end
    end
  end
end
