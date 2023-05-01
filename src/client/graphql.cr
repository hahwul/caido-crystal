require "crystal-gql"

class CaidoClient
    @instance : GraphQLClient

    def initialize(@endpoint : String)
        @instance = GraphQLClient.new endpoint
    end

    def send_query(query : String)
        @instance.useQuery query
    end
end

