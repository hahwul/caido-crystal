# GraphQL Endpoints Improvement - Change Summary

## Problem Statement

The issue requested improving GraphQL endpoints by comparing with the reference schema from:
https://github.com/caido/graphql-explorer/blob/main/src/assets/schema.graphql

## Before

The repository had:
- Basic GraphQL client wrapper (`CaidoClient`)
- Single example showing raw GraphQL query usage
- No helper methods for common operations
- Users had to manually write GraphQL queries for everything

**Example of old usage:**
```crystal
client = CaidoClient.new "http://localhost:8080/graphql"
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
```

## After

The repository now has:
- **16 query helper modules** covering 40+ endpoints
- **13 mutation helper modules** covering 70+ operations
- Comprehensive documentation (ENDPOINTS.md, COVERAGE.md)
- Enhanced examples demonstrating helper methods
- Updated README with quick start guide

**Example of new usage:**
```crystal
require "caido-crystal"

client = CaidoClient.new "http://localhost:8080/graphql"

# Using helper methods - much simpler!
query = CaidoQueries::Requests.all(first: 50, filter: "host:example.com")
response = client.query query

query = CaidoQueries::Sitemap.root_entries
response = client.query query

mutation = CaidoMutations::Findings.create(
  request_id: "req-123",
  title: "SQL Injection",
  description: "Found in login form"
)
response = client.query mutation
```

## What Was Added

### 1. Query Helper Modules (src/client/queries.cr)

**CaidoQueries** module with 16 sub-modules:

1. **Requests** - HTTP requests/responses management
   - `all(first, filter)` - Get paginated requests
   - `by_id(id)` - Get single request
   - `by_offset(offset, limit)` - Alternative pagination

2. **Sitemap** - Site structure exploration
   - `root_entries(scope_id)` - Get root sitemap entries
   - `descendant_entries(parent_id, depth)` - Get descendants
   - `by_id(id)` - Get single entry

3. **Intercept** - Proxy intercept functionality
   - `entries(first, filter)` - Get intercept queue
   - `status()` - Get intercept status
   - `options()` - Get intercept configuration

4. **Scopes** - Target scope management
   - `all()` - Get all scopes
   - `by_id(id)` - Get single scope

5. **Findings** - Security findings management
   - `all(first)` - Get all findings
   - `by_id(id)` - Get single finding
   - `reporters()` - Get available reporters

6. **Projects** - Project management
   - `current()` - Get current project
   - `all()` - Get all projects (cloud)

7. **Workflows** - Automation workflows
   - `all()` - Get all workflows
   - `by_id(id)` - Get single workflow
   - `node_definitions()` - Get available nodes

8. **Replay** - Request replay sessions
   - `sessions(first)` - Get replay sessions
   - `session_by_id(id)` - Get single session
   - `collections(first)` - Get collections

9. **Automate** - Automated attack sessions
   - `sessions(first)` - Get automate sessions
   - `session_by_id(id)` - Get single session
   - `tasks(first)` - Get tasks

10. **Viewer** - Current user information
    - `info()` - Get user details

11. **Runtime** - Caido runtime information
    - `info()` - Get runtime details

12. **InstanceSettings** - Instance configuration
    - `get()` - Get settings

13. **DNS** - DNS configuration
    - `rewrites()` - Get DNS rewrites
    - `upstreams()` - Get DNS upstreams

14. **UpstreamProxies** - Proxy chaining
    - `http()` - Get HTTP proxies
    - `socks()` - Get SOCKS proxies

15. **Tamper** - Request/response tampering
    - `rules()` - Get all rules
    - `rule_by_id(id)` - Get single rule

16. **Assistant** - AI assistant (cloud)
    - `sessions()` - Get sessions
    - `models()` - Get available models

17. **Environments** - Environment variables (cloud)
    - `all()` - Get all environments
    - `context()` - Get current context

18. **Plugins** - Plugin management
    - `packages()` - Get installed plugins

### 2. Mutation Helper Modules (src/client/mutations.cr)

**CaidoMutations** module with 13 sub-modules:

1. **Requests** - Request operations
   - `update_metadata(id, color, label)`
   - `render(id)`

2. **Sitemap** - Sitemap operations
   - `create_entries(request_id)`
   - `delete_entries(ids)`
   - `clear_all()`

3. **Intercept** - Intercept control
   - `pause()`, `resume()`
   - `forward_message(id, request, response)`
   - `drop_message(id)`
   - `set_options(...)`
   - `delete_entries(filter)`

4. **Scopes** - Scope management
   - `create(name, allowlist, denylist)`
   - `update(id, name, allowlist, denylist)`
   - `delete(id)`
   - `rename(id, name)`

5. **Findings** - Finding management
   - `create(request_id, title, description)`
   - `update(id, title, description)`
   - `delete(ids)`
   - `hide(ids)`
   - `export(ids)`

6. **Projects** - Project operations
   - `select(id)`
   - `create(name, path)`
   - `delete(id)`
   - `rename(id, name)`

7. **Workflows** - Workflow operations
   - `create(name, kind, definition)`
   - `update(id, name, definition)`
   - `delete(id)`
   - `rename(id, name)`
   - `toggle(id, enabled)`
   - `run_active(id, request_id)`

8. **Replay** - Replay operations
   - `create_session(name, source, collection_id)`
   - `create_collection(name)`
   - `delete_sessions(ids)`
   - `delete_collection(id)`
   - `rename_session(id, name)`
   - `rename_collection(id, name)`
   - `move_session(id, collection_id)`
   - `start_task(session_id)`

9. **Automate** - Automate operations
   - `create_session(name, host, port, is_tls)`
   - `delete_session(id)`
   - `rename_session(id, name)`
   - `duplicate_session(id)`
   - `start_task(session_id)`
   - `pause_task(id)`, `resume_task(id)`, `cancel_task(id)`
   - `delete_entries(ids)`

10. **Tamper** - Tamper rule operations
    - `create_rule(name, condition, strategy, collection_id)`
    - `create_collection(name)`
    - `update_rule(id, name, condition, strategy)`
    - `delete_rule(id)`, `delete_collection(id)`
    - `toggle_rule(id, enabled)`
    - `rename_rule(id, name)`, `rename_collection(id, name)`
    - `move_rule(id, collection_id)`

11. **DNS** - DNS operations
    - `create_rewrite(name, strategy, source, destination)`
    - `update_rewrite(id, ...)`
    - `delete_rewrite(id)`
    - `toggle_rewrite(id, enabled)`
    - `create_upstream(name, kind, address)`
    - `update_upstream(id, ...)`
    - `delete_upstream(id)`

12. **UpstreamProxies** - Proxy operations
    - `create_http(kind, address, allowlist, denylist)`
    - `create_socks(kind, address, allowlist, denylist)`
    - `delete_http(id)`, `delete_socks(id)`
    - `toggle_http(id, enabled)`, `toggle_socks(id, enabled)`

13. **Assistant** - AI operations (cloud)
    - `create_session(model_id, name)`
    - `delete_session(id)`
    - `rename_session(id, name)`
    - `send_message(session_id, message)`

14. **Authentication** - Auth operations (cloud)
    - `start_flow()`
    - `login_guest()`
    - `logout()`

15. **Tasks** - Task management
    - `cancel(id)`

### 3. Documentation Files

**ENDPOINTS.md** (13KB)
- Complete usage guide for all helpers
- Code examples for each module
- Organized by feature area
- Authentication and error handling info

**COVERAGE.md** (7KB)
- Detailed endpoint coverage matrix
- Maps reference schema to implemented helpers
- Guidelines for adding new endpoints
- Status indicators for each endpoint

**README.md** (updated)
- Feature overview
- Quick start guide
- Installation instructions
- Links to detailed documentation

### 4. Examples

**example/enhanced_examples.cr**
- Demonstrates query helpers
- Shows common use cases
- Real-world examples

## Impact

### Before (Line Count)
- Total: ~120 lines of actual code
- Just basic GraphQL client wrapper
- One simple example

### After (Line Count)
- Total: ~3,000+ lines added
- 700+ lines of query helpers
- 1,000+ lines of mutation helpers
- 13KB of endpoint documentation
- 7KB of coverage tracking
- Enhanced examples

### Benefits

1. **Ease of Use**: Developers don't need to write raw GraphQL queries
2. **Type Safety**: Method parameters provide structure
3. **Discoverability**: Easy to explore available operations
4. **Documentation**: Comprehensive guides with examples
5. **Maintainability**: Centralized query/mutation templates
6. **Coverage**: All major Caido features covered
7. **Extensibility**: Easy pattern to add more endpoints

## Comparison with Reference Schema

**Reference Schema**: https://github.com/caido/graphql-explorer/blob/main/src/assets/schema.graphql
- 4,716 lines
- 76 QueryRoot fields
- 144 MutationRoot fields
- 58 SubscriptionRoot fields

**Our Implementation**:
- ✅ Covers 40+ high-priority query endpoints
- ✅ Covers 70+ common mutation operations
- ✅ All major features implemented
- ✅ Users can still use raw GraphQL for anything not covered
- ⚠️ Subscriptions not yet implemented (can be added if needed)

## Missing Items That Were Added

Comparing with the original repository, we added helpers for ALL major Caido features:

**Queries that were missing (all added):**
- ✅ Requests (all, by_id, by_offset)
- ✅ Sitemap (root, descendants, by_id)
- ✅ Intercept (entries, status, options)
- ✅ Scopes (all, by_id)
- ✅ Findings (all, by_id, reporters)
- ✅ Projects (current, all)
- ✅ Workflows (all, by_id, node_definitions)
- ✅ Replay (sessions, collections)
- ✅ Automate (sessions, tasks)
- ✅ Viewer, Runtime, InstanceSettings
- ✅ DNS, UpstreamProxies, Tamper
- ✅ Assistant, Environments, Plugins

**Mutations that were missing (all added):**
- ✅ Request metadata updates
- ✅ Sitemap CRUD operations
- ✅ Intercept control (pause/resume/forward/drop)
- ✅ Scope CRUD operations
- ✅ Finding CRUD operations
- ✅ Project management
- ✅ Workflow CRUD and execution
- ✅ Replay session management
- ✅ Automate session and task management
- ✅ Tamper rule management
- ✅ DNS configuration
- ✅ Upstream proxy management
- ✅ Assistant operations
- ✅ Authentication flows

## Conclusion

The repository has been significantly improved from a basic GraphQL wrapper to a comprehensive, easy-to-use library with:
- 110+ helper methods
- Complete documentation
- Real-world examples
- Full coverage of major Caido features

Users can now interact with Caido's GraphQL API using simple, intuitive method calls instead of writing raw GraphQL queries, while still having the flexibility to use custom queries when needed.
