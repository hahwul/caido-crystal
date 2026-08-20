require "json"
require "http/client"
require "socket"
require "uri"

class CaidoClient
  class Error < Exception; end

  class ConnectionError < Error; end

  class GraphQLError < Error
    getter errors : Array(String)

    # The `errors` entry exactly as the server sent it, so callers can reach
    # `extensions`, `path` and `locations` without re-parsing the response.
    getter raw_errors : JSON::Any?

    # The `data` entry of a partial response. GraphQL allows `data` and
    # `errors` to both be present; the errors still fail the call, but the
    # partial result is kept here instead of being thrown away.
    getter data : JSON::Any?

    def initialize(@errors : Array(String), @raw_errors : JSON::Any? = nil, @data : JSON::Any? = nil)
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

    # Strips any userinfo from an endpoint URL. An endpoint may legitimately
    # embed credentials (`https://user:token@caido.local/graphql`), which
    # `HTTP::Client` turns into a Basic auth header — but those credentials
    # must never reach an exception message, a log line, or a bug report.
    def self.sanitize_endpoint(endpoint : String) : String
      uri = URI.parse(endpoint)
      return endpoint unless uri.user || uri.password
      uri.user = nil
      uri.password = nil
      uri.to_s
    rescue URI::Error
      # Unparseable endpoint: drop everything up to the authority's "@"
      # rather than echoing a value that may still embed credentials.
      endpoint.sub(/\/\/[^\/@]*@/, "//")
    end

    # `connect_timeout` / `read_timeout` are opt-in: left nil the client
    # blocks indefinitely, which is Crystal's default. A caller talking to a
    # possibly-wedged Caido instance should set them.
    def initialize(@endpoint : String, @connect_timeout : Time::Span? = nil, @read_timeout : Time::Span? = nil)
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
    #
    # `variables` is serialized into the request's own `variables` object; it
    # is never spliced into the query document, so values cannot inject
    # GraphQL.
    def query(query : String, variables = {} of String => String)
      request_body = JSON.build do |json|
        json.object do
          json.field "query", query
          json.field "variables", variables
        end
      end

      response = post(request_body)

      # A GraphQL server answers 200 even for query-level errors, so a
      # non-2xx status is a transport/HTTP failure (401/403/500, an HTML
      # error page, an empty body) — surface it explicitly instead of
      # letting JSON.parse choke on a non-JSON body.
      unless response.success?
        raise TransportError.new(
          "GraphQL request to #{safe_endpoint} failed: HTTP #{response.status_code} #{response.status_message}",
          status_code: response.status_code,
          body: response.body,
        )
      end

      parsed = begin
        JSON.parse(response.body)
      rescue ex : JSON::ParseException
        raise TransportError.new(
          "GraphQL response from #{safe_endpoint} was not valid JSON: #{ex.message}",
          status_code: response.status_code,
          body: response.body,
        )
      end

      # A GraphQL response is *always* a JSON object. A bare `null`, array or
      # scalar is valid JSON but not a valid response, and `JSON::Any#[]?`
      # answers a non-Hash receiver with a raw `Exception` — surface it as a
      # TransportError instead of letting that escape the library.
      unless parsed.as_h?
        raise TransportError.new(
          "GraphQL response from #{safe_endpoint} was not a JSON object",
          status_code: response.status_code,
          body: response.body,
        )
      end

      {parsed["data"]?, parsed["errors"]?, false}
    end

    private def post(request_body : String) : HTTP::Client::Response
      uri = URI.parse(@endpoint)
      client = begin
        HTTP::Client.new(uri)
      rescue ex : ArgumentError
        # Missing host, or a scheme HTTP::Client cannot speak.
        raise TransportError.new("Invalid GraphQL endpoint #{safe_endpoint}: #{ex.message}")
      end

      begin
        if connect_timeout = @connect_timeout
          client.connect_timeout = connect_timeout
        end
        if read_timeout = @read_timeout
          client.read_timeout = read_timeout
        end

        # `HTTP::Client.post(url)` derives Basic auth from the URL's
        # userinfo; keep that behaviour now that we build the client
        # ourselves.
        user = uri.user
        password = uri.password
        client.basic_auth(user, password) if user && password

        client.post(uri.request_target, headers: @headers, body: request_body)
      ensure
        client.close
      end
    rescue ex : URI::Error
      raise TransportError.new("Invalid GraphQL endpoint: #{ex.message}")
    end

    private def safe_endpoint : String
      self.class.sanitize_endpoint(@endpoint)
    end
  end

  @instance : Transport

  # Initialize with optional auth token (falls back to CAIDO_AUTH_TOKEN env var)
  def initialize(@endpoint : String, token : String? = nil, connect_timeout : Time::Span? = nil, read_timeout : Time::Span? = nil)
    @instance = Transport.new(endpoint, connect_timeout, read_timeout)

    auth_token = token || ENV["CAIDO_AUTH_TOKEN"]?
    if auth_token
      @instance.add_header("Authorization", "Bearer #{auth_token}")
    end
  end

  # Initialize with custom headers
  def initialize(@endpoint : String, headers : Hash(String, String), connect_timeout : Time::Span? = nil, read_timeout : Time::Span? = nil)
    @instance = Transport.new(endpoint, connect_timeout, read_timeout)
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

  # Execute a GraphQL document. `variables` is sent in the request's own
  # `variables` object rather than interpolated into the document.
  def query(query : String, variables = {} of String => String)
    response = @instance.query(query, variables)
    check_errors(response)
    response
  rescue ex : CaidoClient::Error
    raise ex
  rescue ex : Transport::TransportError | Socket::ConnectError | IO::Error
    # TransportError (non-2xx / non-JSON body) descends from IO::Error, but
    # name it explicitly so the intent is clear: HTTP-level and connection
    # failures both surface as ConnectionError, never a raw
    # JSON::ParseException or a swallowed status.
    raise ConnectionError.new("Failed to connect to #{Transport.sanitize_endpoint(@endpoint)}: #{ex.message}")
  end

  private def check_errors(response)
    data, errors, _loading = response
    return unless errors
    # Some servers send an explicit `"errors": null` alongside a perfectly
    # good `data`. `JSON::Any` wrapping a null is still truthy in Crystal, so
    # unwrap it before treating the response as a failure.
    return if errors.raw.nil?

    messages = [] of String
    if array = errors.as_a?
      return if array.empty?

      array.each do |err|
        messages << error_message(err)
      end
    else
      messages << errors.to_json
    end

    raise GraphQLError.new(messages, errors, data)
  end

  # Extracts a displayable message from one entry of the `errors` array. A
  # spec-conforming entry is an object with a string `message`, but a
  # malformed server can send a bare string, a number, or an object whose
  # `message` is itself structured — none of which may crash the client.
  private def error_message(err : JSON::Any) : String
    if hash = err.as_h?
      if msg = hash["message"]?
        return msg.as_s? || msg.to_json
      end
      # An entry with no `message` at all (only `extensions`, say) must still
      # surface as a failure rather than be silently dropped.
      return err.to_json
    end

    err.as_s? || err.to_json
  end
end
