+++
title = "Getting Started"
description = "Prerequisites, installation, and your first caido.cr program"
weight = 1
+++

## Prerequisites

Before using caido.cr, ensure your environment meets these requirements:

| Requirement | Details |
|-------------|---------|
| Crystal | >= 1.21.0 |
| Caido | Running instance with GraphQL API enabled |
| Auth Token | `CAIDO_AUTH_TOKEN` environment variable or custom headers |

## Installation

Add the dependency to your `shard.yml`:

```yaml
dependencies:
  caido:
    github: hahwul/caido.cr
```

Then install:

```bash
shards install
```

## Your First Program

Create a file called `hello.cr`:

```crystal
require "caido"

# Create a client pointing to your Caido instance
client = CaidoClient.new "http://localhost:8080/graphql"

# Get current runtime info
query = CaidoQueries::Runtime.info
response = client.query(query)
puts response
```

Run it:

```bash
crystal run hello.cr
```

## Authentication

caido.cr supports two authentication methods:

### Environment Variable (Recommended)

Set the `CAIDO_AUTH_TOKEN` environment variable:

```bash
export CAIDO_AUTH_TOKEN="your-token-here"
crystal run hello.cr
```

The client reads this automatically when no custom headers are provided.

### Custom Headers

Pass authentication headers directly:

```crystal
client = CaidoClient.new(
  "http://localhost:8080/graphql",
  {"Authorization" => "Bearer your-token-here"}
)
```

## Troubleshooting

### Connection refused

Make sure Caido is running and the GraphQL endpoint is accessible:

```bash
curl http://localhost:8080/graphql
```

### Authentication errors

Verify your token is valid. You can find it in Caido's settings or generate a new one from the Caido UI.

### Missing dependencies

Run `shards install` to ensure `crystal-gql` and other dependencies are installed.
