require "crystal-gql"

class CaidoClient
  class Error < Exception; end

  class ConnectionError < Error; end

  class GraphQLError < Error
    getter errors : Array(String)

    def initialize(@errors : Array(String))
      super(@errors.join("; "))
    end
  end

  @instance : GraphQLClient

  # Initialize with optional auth token (falls back to CAIDO_AUTH_TOKEN env var)
  def initialize(@endpoint : String, token : String? = nil)
    @instance = GraphQLClient.new endpoint

    auth_token = token || ENV["CAIDO_AUTH_TOKEN"]?
    if auth_token
      @instance.add_header("Authorization", "Bearer #{auth_token}")
    end
  end

  # Initialize with custom headers
  def initialize(@endpoint : String, headers : Hash(String, String))
    @instance = GraphQLClient.new endpoint
    headers.each do |key, value|
      @instance.add_header(key, value)
    end
  end

  def query(query : String)
    response = @instance.query query
    check_errors(response)
    response
  rescue ex : CaidoClient::Error
    raise ex
  rescue ex : Socket::ConnectError | IO::Error
    raise ConnectionError.new("Failed to connect to #{@endpoint}: #{ex.message}")
  end

  private def check_errors(response)
    _data, error, _loading = response
    if error
      messages = [] of String
      if error.as_a?
        error.as_a.each do |err|
          if msg = err["message"]?
            messages << msg.as_s
          end
        end
      else
        messages << error.to_s
      end
      raise GraphQLError.new(messages) unless messages.empty?
    end
  end
end
