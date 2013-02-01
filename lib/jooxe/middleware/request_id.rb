require 'securerandom'

module Jooxe
  
  # originally copied from https://raw.github.com/rails/rails/master/actionpack/lib/action_dispatch/middleware/request_id.rb
  # 
  # Makes a unique request id available to the action_dispatch.request_id env variable 
  # and sends the same id to the client via the X-Request-Id header.
  #
  # The unique request id is either based off the X-Request-Id header in the request, which would typically be generated
  # by a firewall, load balancer, or the web server, or, if this header is not available, a random uuid. If the
  # header is accepted from the outside world, we sanitize it to a max of 255 chars and alphanumeric and dashes only.
  #
  # The unique request id can be used to trace a request end-to-end and would typically end up being part of log files
  # from multiple pieces of the stack.
  class RequestId
    def initialize(app)
      @app = app
    end

    def call(env)
      env["jooxe.request_id"] = external_request_id(env) || internal_request_id
      @app.call(env).tap { |status, headers, body| headers["X-Request-Id"] = env["jooxe.request_id"] }
    end

    private
      def external_request_id(env)
        if request_id = env["HTTP_X_REQUEST_ID"].presence
          request_id.gsub(/[^\w\-]/, "").first(255)
        end
      end

      def internal_request_id
        SecureRandom.uuid
      end
  end
end