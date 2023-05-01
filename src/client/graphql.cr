require "crystal-gql"

class CaidoClient
    @instance : GraphQLClient

    def initialize(@endpoint : String)
        @instance = GraphQLClient.new endpoint
    end

    def query(query : String)
        @instance.query query
    end
end

