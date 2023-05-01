require "crystal-gql"

class CaidoClient
    @instance : GraphQLClient

    def initialize(@endpoint : String)
        @instance = GraphQLClient.new endpoint
    end

    def send_query(query : String, data : Hash(String, String))
        @instance.instance.send_query query, data
    end
end

