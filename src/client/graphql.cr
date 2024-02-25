require "crystal-gql"

class CaidoClient
  @instance : GraphQLClient
  @headers : Hash(String, String)

  # Initialize
  def initialize(@endpoint : String)
    @instance = GraphQLClient.new endpoint
    @headers = Hash(String, String).new

    if ENV.has_key? "CAIDO_AUTH_TOKEN"
      @instance.headers["Authorization"] = "Bearer #{ENV["CAIDO_AUTH_TOKEN"]}"
      @headers["Authorization"] = "Bearer #{ENV["CAIDO_AUTH_TOKEN"]}"
    end
  end

  # Initialize with custom headers
  def initialize(@endpoint : String, @headers : Hash(String, String))
    @instance = GraphQLClient.new endpoint, @headers
  end

  def query(query : String)
    @instance.query query
  end
end
