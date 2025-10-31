# GraphQL Endpoint Coverage

This document lists the GraphQL endpoints from the [Caido GraphQL schema](https://github.com/caido/graphql-explorer/blob/main/src/assets/schema.graphql) and their implementation status in caido-crystal.

## Query Endpoints (QueryRoot)

| Endpoint | Module | Method | Status |
|----------|--------|--------|--------|
| assistantModels | CaidoQueries::Assistant | models | ✅ |
| assistantSession | CaidoQueries::Assistant | - | ⚠️ Use by_id pattern if needed |
| assistantSessions | CaidoQueries::Assistant | sessions | ✅ |
| authenticationState | - | - | ➕ Can add if needed |
| automateEntry | CaidoQueries::Automate | - | ⚠️ Use by_id pattern if needed |
| automateSession | CaidoQueries::Automate | session_by_id | ✅ |
| automateSessions | CaidoQueries::Automate | sessions | ✅ |
| automateTasks | CaidoQueries::Automate | tasks | ✅ |
| backup | - | - | ➕ Can add if needed |
| backupTasks | - | - | ➕ Can add if needed |
| backups | - | - | ➕ Can add if needed |
| browser | - | - | ➕ Can add if needed |
| currentProject | CaidoQueries::Projects | current | ✅ |
| dataExport | - | - | ➕ Can add if needed |
| dataExports | - | - | ➕ Can add if needed |
| dnsRewrites | CaidoQueries::DNS | rewrites | ✅ |
| dnsUpstreams | CaidoQueries::DNS | upstreams | ✅ |
| environment | CaidoQueries::Environments | - | ⚠️ Use by_id pattern if needed |
| environmentContext | CaidoQueries::Environments | context | ✅ |
| environments | CaidoQueries::Environments | all | ✅ |
| filterPreset | - | - | ➕ Can add if needed |
| filterPresets | - | - | ➕ Can add if needed |
| finding | CaidoQueries::Findings | by_id | ✅ |
| findingReporters | CaidoQueries::Findings | reporters | ✅ |
| findings | CaidoQueries::Findings | all | ✅ |
| findingsByOffset | - | - | ⚠️ Similar to findings |
| globalConfig | - | - | ➕ Can add if needed |
| hostedFiles | - | - | ➕ Can add if needed |
| instanceSettings | CaidoQueries::InstanceSettings | get | ✅ |
| interceptEntries | CaidoQueries::Intercept | entries | ✅ |
| interceptEntriesByOffset | - | - | ⚠️ Similar to entries |
| interceptEntry | - | - | ⚠️ Use by_id pattern if needed |
| interceptEntryOffset | - | - | ➕ Can add if needed |
| interceptMessages | - | - | ➕ Can add if needed |
| interceptOptions | CaidoQueries::Intercept | options | ✅ |
| interceptStatus | CaidoQueries::Intercept | status | ✅ |
| pluginPackages | CaidoQueries::Plugins | packages | ✅ |
| projects | CaidoQueries::Projects | all | ✅ |
| replayEntry | - | - | ⚠️ Use by_id pattern if needed |
| replaySession | CaidoQueries::Replay | session_by_id | ✅ |
| replaySessionCollections | CaidoQueries::Replay | collections | ✅ |
| replaySessions | CaidoQueries::Replay | sessions | ✅ |
| request | CaidoQueries::Requests | by_id | ✅ |
| requestOffset | - | - | ➕ Can add if needed |
| requests | CaidoQueries::Requests | all | ✅ |
| requestsByOffset | CaidoQueries::Requests | by_offset | ✅ |
| response | - | - | ⚠️ Included in request query |
| restoreBackupTasks | - | - | ➕ Can add if needed |
| runtime | CaidoQueries::Runtime | info | ✅ |
| scope | CaidoQueries::Scopes | by_id | ✅ |
| scopes | CaidoQueries::Scopes | all | ✅ |
| sitemapDescendantEntries | CaidoQueries::Sitemap | descendant_entries | ✅ |
| sitemapEntry | CaidoQueries::Sitemap | by_id | ✅ |
| sitemapRootEntries | CaidoQueries::Sitemap | root_entries | ✅ |
| store | - | - | ➕ Can add if needed |
| stream | - | - | ➕ Can add if needed |
| streamWsMessage | - | - | ➕ Can add if needed |
| streamWsMessageEdit | - | - | ➕ Can add if needed |
| streamWsMessages | - | - | ➕ Can add if needed |
| streamWsMessagesByOffset | - | - | ➕ Can add if needed |
| streams | - | - | ➕ Can add if needed |
| streamsByOffset | - | - | ➕ Can add if needed |
| tamperRule | CaidoQueries::Tamper | rule_by_id | ✅ |
| tamperRuleCollection | - | - | ⚠️ Included in rules query |
| tamperRuleCollections | CaidoQueries::Tamper | rules | ✅ |
| tasks | - | - | ➕ Can add if needed |
| upstreamProxiesHttp | CaidoQueries::UpstreamProxies | http | ✅ |
| upstreamProxiesSocks | CaidoQueries::UpstreamProxies | socks | ✅ |
| viewer | CaidoQueries::Viewer | info | ✅ |
| workflow | CaidoQueries::Workflows | by_id | ✅ |
| workflowNodeDefinitions | CaidoQueries::Workflows | node_definitions | ✅ |
| workflows | CaidoQueries::Workflows | all | ✅ |

## Mutation Endpoints (MutationRoot)

Major mutation categories covered:

| Category | Methods | Status |
|----------|---------|--------|
| Requests | update_metadata, render | ✅ |
| Sitemap | create_entries, delete_entries, clear_all | ✅ |
| Intercept | pause, resume, forward_message, drop_message, set_options, delete_entries | ✅ |
| Scopes | create, update, delete, rename | ✅ |
| Findings | create, update, delete, hide, export | ✅ |
| Projects | select, create, delete, rename | ✅ |
| Workflows | create, update, delete, rename, toggle, run_active | ✅ |
| Replay | create_session, create_collection, delete_sessions, delete_collection, rename_session, rename_collection, move_session, start_task | ✅ |
| Automate | create_session, delete_session, rename_session, duplicate_session, start_task, pause_task, resume_task, cancel_task, delete_entries | ✅ |
| Tamper | create_rule, create_collection, update_rule, delete_rule, delete_collection, toggle_rule, rename_rule, rename_collection, move_rule | ✅ |
| DNS | create_rewrite, update_rewrite, delete_rewrite, toggle_rewrite, create_upstream, update_upstream, delete_upstream | ✅ |
| UpstreamProxies | create_http, create_socks, delete_http, delete_socks, toggle_http, toggle_socks | ✅ |
| Assistant | create_session, delete_session, rename_session, send_message | ✅ |
| Authentication | start_flow, login_guest, logout | ✅ |
| Tasks | cancel | ✅ |

Additional mutations available in the schema (100+ total) can be added as needed using the same pattern.

## Coverage Summary

- **Query Endpoints**: ~40 high-priority endpoints implemented ✅
- **Mutation Endpoints**: ~70 common mutations implemented ✅
- **Total Coverage**: Major functionality covered for all key features

## Legend

- ✅ = Implemented
- ⚠️ = Partially implemented or alternative available
- ➕ = Can be added if needed (low priority)

## Notes

1. The implementation focuses on the most commonly used endpoints
2. All major Caido features are covered (requests, sitemap, intercept, findings, workflows, etc.)
3. Additional endpoints can be easily added following the same pattern
4. Users can still use raw GraphQL queries for any endpoint not covered by helpers
5. Some endpoints are intentionally grouped (e.g., tamperRuleCollections includes rules)

## Adding New Endpoints

To add a new endpoint helper:

1. **For queries**: Add a new method in the appropriate module under `CaidoQueries`
2. **For mutations**: Add a new method in the appropriate module under `CaidoMutations`
3. Follow the existing pattern of using heredoc strings with parameterized values
4. Update this coverage document
5. Add examples to ENDPOINTS.md

Example:
```crystal
module CaidoQueries
  module MyFeature
    def self.my_method(param : String)
      %Q(
        query MyQuery {
          myEndpoint(id: "#{param}") {
            id
            name
          }
        }
      )
    end
  end
end
```
