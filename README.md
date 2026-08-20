# caido.cr

Crystal language client library for [Caido](https://caido.io/), a lightweight web security auditing toolkit.

## Features

- **Simple GraphQL Client**: Easy-to-use wrapper for Caido's GraphQL API
- **Pre-built Query Helpers**: Ready-to-use templates for common operations
- **Comprehensive Mutation Support**: Helper methods for all major Caido operations
- **Full API Coverage**: Supports requests, sitemap, intercept, findings, workflows, and more

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  caido:
    github: hahwul/caido.cr
```

Run `shards install` to install dependencies.

## Quick Start

### Basic Usage

```crystal
require "caido"

# Initialize the client
client = CaidoClient.new "http://localhost:8080/graphql"

# Get all requests
query = CaidoQueries::Requests.all(first: 50)
response = client.query query
puts response

# Get sitemap root entries
query = CaidoQueries::Sitemap.root_entries
response = client.query query
puts response
```

### Authentication

Set the authentication token via environment variable:

```bash
export CAIDO_AUTH_TOKEN="your-token-here"
```

Or provide custom headers:

```crystal
headers = {"Authorization" => "Bearer your-token-here"}
client = CaidoClient.new "http://localhost:8080/graphql", headers
```

### Timeouts

Requests block indefinitely by default. Pass timeouts to bound them:

```crystal
client = CaidoClient.new(
  "http://localhost:8080/graphql",
  connect_timeout: 5.seconds,
  read_timeout: 30.seconds
)
```

### Variables

Custom documents can take variables. They are sent in the GraphQL request's
own `variables` object, never interpolated into the document:

```crystal
client.query(
  "query GetRequest($id: ID!) { request(id: $id) { id host } }",
  {"id" => "12345"}
)
```

### Error handling

- `CaidoClient::ConnectionError` — the request never produced a GraphQL
  response (connection failure, timeout, non-2xx status, non-JSON body).
- `CaidoClient::GraphQLError` — the server answered with `errors`. Besides
  `#errors` (the messages), it carries `#raw_errors` (the untouched `errors`
  entry, so `extensions`/`path`/`locations` stay reachable) and `#data` (the
  partial result of a `data` + `errors` response).

### Examples

See the `examples/` directory for usage examples:
- `get_sitemap.cr` - Basic example
- `enhanced_examples.cr` - Comprehensive examples using helper methods

## Available Endpoints

The library includes helper modules for common operations:

### Query Modules (CaidoQueries)
- **Requests**: HTTP requests and responses
- **Sitemap**: Target site structure
- **Intercept**: Proxy intercept functionality
- **Scopes**: Target scope management
- **Findings**: Security findings
- **Projects**: Project management
- **Workflows**: Automation workflows
- **Replay**: Request replay sessions
- **Automate**: Automated attacks
- **Viewer**: Current user info
- **Runtime**: Caido runtime info
- And many more...

### Mutation Modules (CaidoMutations)
- **Requests**: Update metadata, render requests
- **Sitemap**: Create, delete entries
- **Intercept**: Pause, resume, forward/drop messages
- **Scopes**: Create, update, delete scopes
- **Findings**: Create, update, delete findings
- **Workflows**: Create, update, run workflows
- **Replay**: Manage replay sessions
- **Automate**: Manage automate sessions and tasks
- **MatchReplace**: Manage tampering rules
- And many more...

For complete documentation of all available endpoints, see [ENDPOINTS.md](ENDPOINTS.md).

## Documentation

- [Complete Endpoint Documentation](ENDPOINTS.md) - Detailed guide for all queries and mutations
- [Caido Official Documentation](https://docs.caido.io/)
- [Caido GraphQL Schema](https://github.com/caido/graphql-explorer/blob/main/src/assets/schema.graphql)

## Development

Build the project:
```bash
shards build
```

Run tests:
```bash
crystal spec
```

## Contributing

1. Fork it (<https://github.com/hahwul/caido.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [hahwul](https://github.com/hahwul) - creator and maintainer

## License

MIT License - see [LICENSE](LICENSE) file for details