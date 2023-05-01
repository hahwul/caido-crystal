require "spec"
require "../src/client/graphql"

client = CaidoClient.new "http://localhost:8080/graphql"
# send GQL Query to server and get response.
response = client.query "query GetProject{
	requests {
		nodes {
    	method
    	host
      path
      query
    }
  }
}"

puts response
