require "json"
require "http/client"
require "socket"

class CaidoClient
  class Error < Exception; end

  class ConnectionError < Error; end

  class GraphQLError < Error
    getter errors : Array(String)

    def initialize(@errors : Array(String))
      super(@errors.join("; "))
    end
  end

  # Minimal GraphQL-over-HTTP transport. caido only ever POSTs a query and
  # decodes the `{data, errors, loading}` response, so we own those few lines
  # instead of depending on an external GraphQL-client shard. This keeps the
  # error-handling contract (plural `errors`, nil-safe `data`, explicit HTTP
  # status checks) in one place under our control.
  class Transport
    # Raised when the transport fails before a well-formed GraphQL response
    # can be produced: a non-2xx HTTP status, or a body that is not valid
    # JSON. Descends from `IO::Error` so callers that already rescue
    # transport-level failures (connection resets) catch it too, and a bare
    # `JSON::ParseException` never leaks for an HTML error page.
    class TransportError < IO::Error
      getter status_code : Int32?
      getter body : String?

      def initialize(message : String, @status_code : Int32? = nil, @body : String? = nil)
        super(message)
      end
    end

    def initialize(@endpoint : String)
      @headers = HTTP::Headers{
        "accept"       => "application/json",
        "content-type" => "application/json",
      }
    end

    def add_header(key : String, value : String)
      @headers[key] = value
    end

    # POST a GraphQL query and return the decoded `{data, errors, loading}`
    # tuple. `data` is read nil-safely (an errors-only response omits it) and
    # failures live under the *plural* `errors` key — the singular `error` is
    # never part of the GraphQL spec.
    def query(query : String, variables = {} of String => String)
      request_body = JSON.build do |json|
        json.object do
          json.field "query", query
          json.field "variables", variables
        end
      end

      response = HTTP::Client.post(@endpoint, headers: @headers, body: request_body)

      # A GraphQL server answers 200 even for query-level errors, so a
      # non-2xx status is a transport/HTTP failure (401/403/500, an HTML
      # error page, an empty body) — surface it explicitly instead of
      # letting JSON.parse choke on a non-JSON body.
      unless response.success?
        raise TransportError.new(
          "GraphQL request to #{@endpoint} failed: HTTP #{response.status_code} #{response.status_message}",
          status_code: response.status_code,
          body: response.body,
        )
      end

      parsed = begin
        JSON.parse(response.body)
      rescue ex : JSON::ParseException
        raise TransportError.new(
          "GraphQL response from #{@endpoint} was not valid JSON: #{ex.message}",
          status_code: response.status_code,
          body: response.body,
        )
      end

      {parsed["data"]?, parsed.dig?("errors"), false}
    end
  end

  @instance : Transport

  # Initialize with optional auth token (falls back to CAIDO_AUTH_TOKEN env var)
  def initialize(@endpoint : String, token : String? = nil)
    @instance = Transport.new endpoint

    auth_token = token || ENV["CAIDO_AUTH_TOKEN"]?
    if auth_token
      @instance.add_header("Authorization", "Bearer #{auth_token}")
    end
  end

  # Initialize with custom headers
  def initialize(@endpoint : String, headers : Hash(String, String))
    @instance = Transport.new endpoint
    headers.each do |key, value|
      @instance.add_header(key, value)
    end
  end

  # Initialize with a caller-supplied transport. This is the seam tests use to
  # drive the client against scripted responses without a live server; the
  # transport only has to respond to `#query(String)` with a
  # `{data, errors, loading}` tuple.
  def initialize(@endpoint : String, instance : Transport)
    @instance = instance
  end

  def query(query : String)
    response = @instance.query query
    check_errors(response)
    response
  rescue ex : CaidoClient::Error
    raise ex
  rescue ex : Transport::TransportError | Socket::ConnectError | IO::Error
    # TransportError (non-2xx / non-JSON body) descends from IO::Error, but
    # name it explicitly so the intent is clear: HTTP-level and connection
    # failures both surface as ConnectionError, never a raw
    # JSON::ParseException or a swallowed status.
    raise ConnectionError.new("Failed to connect to #{@endpoint}: #{ex.message}")
  end

  private def check_errors(response)
    _data, errors, _loading = response
    return unless errors

    messages = [] of String
    if array = errors.as_a?
      array.each do |err|
        if msg = err["message"]?
          # A GraphQL error `message` SHOULD be a string, but a malformed or
          # non-conforming server can send a number/object/array. Read it
          # nil-safely and fall back to `to_s` so the error still surfaces as
          # a GraphQLError instead of crashing with a raw TypeCastError.
          messages << (msg.as_s? || msg.to_s)
        end
      end
    else
      messages << errors.to_s
    end
    raise GraphQLError.new(messages) unless messages.empty?
  end
end
