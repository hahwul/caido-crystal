# Caido GraphQL Endpoints

This document provides an overview of the available GraphQL endpoints in the caido-crystal library.

## Overview

The library now includes helper modules for common Caido GraphQL operations:
- **CaidoQueries**: Pre-built query templates for fetching data
- **CaidoMutations**: Pre-built mutation templates for modifying data

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  caido-crystal:
    github: hahwul/caido-crystal
```

## Usage

### Basic Setup

```crystal
require "caido-crystal"

client = CaidoClient.new "http://localhost:8080/graphql"
```

### Authentication

The client automatically uses the `CAIDO_AUTH_TOKEN` environment variable if available:

```bash
export CAIDO_AUTH_TOKEN="your-token-here"
```

Or provide custom headers:

```crystal
headers = {"Authorization" => "Bearer your-token-here"}
client = CaidoClient.new "http://localhost:8080/graphql", headers
```

## Query Modules

### Requests

Get HTTP requests and responses from Caido's history.

```crystal
# Get all requests with pagination
query = CaidoQueries::Requests.all(first: 50)
response = client.query query

# Get requests with HTTPQL filter
query = CaidoQueries::Requests.all(first: 50, filter: "host:example.com")
response = client.query query

# Get a single request by ID
query = CaidoQueries::Requests.by_id("request-id-here")
response = client.query query

# Get requests by offset (alternative pagination)
query = CaidoQueries::Requests.by_offset(offset: 0, limit: 50)
response = client.query query
```

### Sitemap

Explore the target sitemap hierarchy.

```crystal
# Get root sitemap entries
query = CaidoQueries::Sitemap.root_entries
response = client.query query

# Get root entries for a specific scope
query = CaidoQueries::Sitemap.root_entries(scope_id: "scope-id")
response = client.query query

# Get descendant entries of a parent
query = CaidoQueries::Sitemap.descendant_entries(parent_id: "parent-id", depth: "DIRECT")
response = client.query query

# Get a single sitemap entry
query = CaidoQueries::Sitemap.by_id("entry-id")
response = client.query query
```

### Intercept

Manage HTTP intercept proxy functionality.

```crystal
# Get intercept entries
query = CaidoQueries::Intercept.entries(first: 50)
response = client.query query

# Get intercept status
query = CaidoQueries::Intercept.status
response = client.query query

# Get intercept options
query = CaidoQueries::Intercept.options
response = client.query query
```

### Scopes

Manage target scopes with allowlists and denylists.

```crystal
# Get all scopes
query = CaidoQueries::Scopes.all
response = client.query query

# Get a single scope
query = CaidoQueries::Scopes.by_id("scope-id")
response = client.query query
```

### Findings

Manage security findings discovered during testing.

```crystal
# Get all findings
query = CaidoQueries::Findings.all(first: 50)
response = client.query query

# Get a single finding
query = CaidoQueries::Findings.by_id("finding-id")
response = client.query query

# Get finding reporters
query = CaidoQueries::Findings.reporters
response = client.query query
```

### Projects

Manage Caido projects (requires cloud subscription).

```crystal
# Get current project
query = CaidoQueries::Projects.current
response = client.query query

# Get all projects
query = CaidoQueries::Projects.all
response = client.query query
```

### Workflows

Manage passive and active workflows for automation.

```crystal
# Get all workflows
query = CaidoQueries::Workflows.all
response = client.query query

# Get a single workflow
query = CaidoQueries::Workflows.by_id("workflow-id")
response = client.query query

# Get workflow node definitions
query = CaidoQueries::Workflows.node_definitions
response = client.query query
```

### Replay

Manage replay sessions for request testing.

```crystal
# Get replay sessions
query = CaidoQueries::Replay.sessions(first: 50)
response = client.query query

# Get a single replay session
query = CaidoQueries::Replay.session_by_id("session-id")
response = client.query query

# Get replay session collections
query = CaidoQueries::Replay.collections(first: 50)
response = client.query query
```

### Automate

Manage automated attack sessions.

```crystal
# Get automate sessions
query = CaidoQueries::Automate.sessions(first: 50)
response = client.query query

# Get a single automate session
query = CaidoQueries::Automate.session_by_id("session-id")
response = client.query query

# Get automate tasks
query = CaidoQueries::Automate.tasks(first: 50)
response = client.query query
```

### Additional Query Modules

- **Viewer**: Get current user information
- **Runtime**: Get Caido runtime information
- **InstanceSettings**: Get and manage instance settings
- **DNS**: Manage DNS rewrites and upstreams
- **UpstreamProxies**: Manage HTTP and SOCKS upstream proxies
- **Tamper**: Manage request/response tampering rules
- **Assistant**: AI assistant sessions (requires cloud)
- **Environments**: Manage environment variables (requires cloud)
- **Plugins**: Manage installed plugins

## Mutation Modules

### Request Mutations

Modify request metadata and properties.

```crystal
# Update request metadata (color, label)
mutation = CaidoMutations::Requests.update_metadata(
  request_id: "request-id",
  color: "#FF0000",
  label: "Important"
)
response = client.query mutation

# Render a request with environment variables
mutation = CaidoMutations::Requests.render(request_id: "request-id")
response = client.query mutation
```

### Sitemap Mutations

Manage sitemap entries.

```crystal
# Create sitemap entries from a request
mutation = CaidoMutations::Sitemap.create_entries(request_id: "request-id")
response = client.query mutation

# Delete sitemap entries
mutation = CaidoMutations::Sitemap.delete_entries(["entry-id-1", "entry-id-2"])
response = client.query mutation

# Clear all sitemap entries
mutation = CaidoMutations::Sitemap.clear_all
response = client.query mutation
```

### Intercept Mutations

Control intercept proxy behavior.

```crystal
# Pause intercept
mutation = CaidoMutations::Intercept.pause
response = client.query mutation

# Resume intercept
mutation = CaidoMutations::Intercept.resume
response = client.query mutation

# Forward an intercept message (optionally modified)
mutation = CaidoMutations::Intercept.forward_message(
  message_id: "message-id",
  request: "modified-request-here"
)
response = client.query mutation

# Drop an intercept message
mutation = CaidoMutations::Intercept.drop_message(message_id: "message-id")
response = client.query mutation

# Set intercept options
mutation = CaidoMutations::Intercept.set_options(
  request_enabled: true,
  response_enabled: false,
  in_scope_only: true
)
response = client.query mutation
```

### Scope Mutations

Create and manage scopes.

```crystal
# Create a new scope
mutation = CaidoMutations::Scopes.create(
  name: "Test Scope",
  allowlist: ["https://example.com/*"],
  denylist: ["https://example.com/admin/*"]
)
response = client.query mutation

# Update a scope
mutation = CaidoMutations::Scopes.update(
  scope_id: "scope-id",
  name: "Updated Scope",
  allowlist: ["https://example.com/*", "https://test.com/*"]
)
response = client.query mutation

# Delete a scope
mutation = CaidoMutations::Scopes.delete(scope_id: "scope-id")
response = client.query mutation

# Rename a scope
mutation = CaidoMutations::Scopes.rename(scope_id: "scope-id", name: "New Name")
response = client.query mutation
```

### Finding Mutations

Create and manage security findings.

```crystal
# Create a finding
mutation = CaidoMutations::Findings.create(
  request_id: "request-id",
  title: "SQL Injection",
  description: "Potential SQL injection vulnerability",
  reporter: "Manual"
)
response = client.query mutation

# Update a finding
mutation = CaidoMutations::Findings.update(
  finding_id: "finding-id",
  title: "Confirmed SQL Injection",
  description: "Updated description"
)
response = client.query mutation

# Delete findings
mutation = CaidoMutations::Findings.delete(["finding-id-1", "finding-id-2"])
response = client.query mutation

# Hide findings
mutation = CaidoMutations::Findings.hide(["finding-id-1", "finding-id-2"])
response = client.query mutation

# Export findings
mutation = CaidoMutations::Findings.export(["finding-id-1", "finding-id-2"])
response = client.query mutation
```

### Workflow Mutations

Manage workflow automation.

```crystal
# Create a workflow (requires cloud)
mutation = CaidoMutations::Workflows.create(
  name: "Custom Workflow",
  kind: "ACTIVE",
  definition: "workflow-definition-json"
)
response = client.query mutation

# Update a workflow
mutation = CaidoMutations::Workflows.update(
  workflow_id: "workflow-id",
  name: "Updated Workflow",
  definition: "new-definition-json"
)
response = client.query mutation

# Toggle workflow enabled state
mutation = CaidoMutations::Workflows.toggle(workflow_id: "workflow-id", enabled: true)
response = client.query mutation

# Run an active workflow
mutation = CaidoMutations::Workflows.run_active(
  workflow_id: "workflow-id",
  request_id: "request-id"
)
response = client.query mutation

# Delete a workflow
mutation = CaidoMutations::Workflows.delete(workflow_id: "workflow-id")
response = client.query mutation
```

### Replay Mutations

Manage replay sessions and collections.

```crystal
# Create a replay session
mutation = CaidoMutations::Replay.create_session(
  name: "Test Session",
  source: "request-source",
  collection_id: "collection-id"
)
response = client.query mutation

# Create a replay session collection
mutation = CaidoMutations::Replay.create_collection(name: "My Collection")
response = client.query mutation

# Delete replay sessions
mutation = CaidoMutations::Replay.delete_sessions(["session-id-1", "session-id-2"])
response = client.query mutation

# Move a replay session to a collection
mutation = CaidoMutations::Replay.move_session(
  session_id: "session-id",
  collection_id: "collection-id"
)
response = client.query mutation

# Start a replay task (requires cloud)
mutation = CaidoMutations::Replay.start_task(session_id: "session-id")
response = client.query mutation
```

### Automate Mutations

Manage automate sessions and tasks.

```crystal
# Create an automate session
mutation = CaidoMutations::Automate.create_session(
  name: "Test Session",
  host: "example.com",
  port: 443,
  is_tls: true
)
response = client.query mutation

# Start an automate task
mutation = CaidoMutations::Automate.start_task(session_id: "session-id")
response = client.query mutation

# Pause an automate task
mutation = CaidoMutations::Automate.pause_task(task_id: "task-id")
response = client.query mutation

# Resume an automate task
mutation = CaidoMutations::Automate.resume_task(task_id: "task-id")
response = client.query mutation

# Cancel an automate task
mutation = CaidoMutations::Automate.cancel_task(task_id: "task-id")
response = client.query mutation
```

### Tamper Mutations

Manage request/response tampering rules.

```crystal
# Create a tamper rule
mutation = CaidoMutations::Tamper.create_rule(
  name: "Add Header",
  condition: "request.host == 'example.com'",
  strategy: "add-header-strategy",
  collection_id: "collection-id"
)
response = client.query mutation

# Create a tamper rule collection
mutation = CaidoMutations::Tamper.create_collection(name: "My Rules")
response = client.query mutation

# Toggle tamper rule enabled state
mutation = CaidoMutations::Tamper.toggle_rule(rule_id: "rule-id", enabled: true)
response = client.query mutation

# Update a tamper rule
mutation = CaidoMutations::Tamper.update_rule(
  rule_id: "rule-id",
  name: "Updated Rule",
  condition: "new-condition"
)
response = client.query mutation

# Delete a tamper rule
mutation = CaidoMutations::Tamper.delete_rule(rule_id: "rule-id")
response = client.query mutation
```

### Additional Mutation Modules

- **Projects**: Create, select, delete, and rename projects (requires cloud)
- **DNS**: Manage DNS rewrites and upstreams
- **UpstreamProxies**: Manage HTTP and SOCKS upstream proxies
- **Assistant**: AI assistant operations (requires cloud)
- **Authentication**: Login, logout, authentication flows (requires cloud)
- **Tasks**: Cancel running tasks

## Custom Queries

For operations not covered by the helper modules, you can still use raw GraphQL:

```crystal
client = CaidoClient.new "http://localhost:8080/graphql"

custom_query = %Q(
  query CustomQuery {
    requests(first: 10) {
      nodes {
        id
        host
        path
      }
    }
  }
)

response = client.query custom_query
```

## Error Handling

GraphQL responses include errors in the response body. Check for errors:

```crystal
response = client.query query
# Parse response and check for errors field
```

## Cloud Features

Some features require a Caido Cloud subscription and are marked with `@cloud` in the schema:
- Projects management
- Assistant (AI) features
- Some workflow operations
- Advanced replay features

## Additional Resources

- [Caido Documentation](https://docs.caido.io/)
- [Caido GraphQL Explorer](https://github.com/caido/graphql-explorer)
- [Official Caido GraphQL Schema](https://github.com/caido/graphql-explorer/blob/main/src/assets/schema.graphql)

## Contributing

Contributions are welcome! If you find missing endpoints or have improvements, please open an issue or pull request.

## License

MIT License - see LICENSE file for details
