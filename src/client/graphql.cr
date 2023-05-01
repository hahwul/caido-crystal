require "crystal-gql"

class CaidoClient
    @instance : GraphQLClient
    
    def initialize(@endpoint : String)
        @instance = GraphQLClient.new endpoint
    end
end