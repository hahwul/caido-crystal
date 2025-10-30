require "spec"
require "../src/client/graphql"
require "../src/client/queries"
require "../src/client/mutations"

# Initialize the Caido client
client = CaidoClient.new "http://localhost:8080/graphql"

puts "=== Caido Crystal Library - Enhanced Examples ==="
puts

# Example 1: Get all requests using the helper
puts "1. Getting requests using helper method:"
query = CaidoQueries::Requests.all(first: 10)
response = client.query query
puts response
puts

# Example 2: Get sitemap root entries
puts "2. Getting sitemap root entries:"
query = CaidoQueries::Sitemap.root_entries
response = client.query query
puts response
puts

# Example 3: Get intercept status
puts "3. Getting intercept status:"
query = CaidoQueries::Intercept.status
response = client.query query
puts response
puts

# Example 4: Get current project information
puts "4. Getting current project:"
query = CaidoQueries::Projects.current
response = client.query query
puts response
puts

# Example 5: Get all scopes
puts "5. Getting all scopes:"
query = CaidoQueries::Scopes.all
response = client.query query
puts response
puts

# Example 6: Get findings
puts "6. Getting findings:"
query = CaidoQueries::Findings.all(first: 5)
response = client.query query
puts response
puts

# Example 7: Get viewer (current user) information
puts "7. Getting viewer information:"
query = CaidoQueries::Viewer.info
response = client.query query
puts response
puts

# Example 8: Get runtime information
puts "8. Getting runtime information:"
query = CaidoQueries::Runtime.info
response = client.query query
puts response
puts

# Example 9: Mutation - Pause intercept (commented out to avoid side effects)
# puts "9. Pausing intercept:"
# mutation = CaidoMutations::Intercept.pause
# response = client.query mutation
# puts response
# puts

# Example 10: Get workflows
puts "10. Getting workflows:"
query = CaidoQueries::Workflows.all
response = client.query query
puts response
puts

puts "=== Examples Complete ==="
