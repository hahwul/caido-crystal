require "./utils"

module CaidoQueries
  # Query templates for common Caido GraphQL operations

  # Reusable GraphQL field fragments
  METADATA_FIELDS = <<-GQL
    metadata {
      id
      color
    }
    GQL

  REQUEST_FIELDS = <<-GQL
    id
    host
    port
    path
    query
    method
    edited
    isTls
    length
    alteration
    #{METADATA_FIELDS}
    fileExtension
    source
    createdAt
    GQL

  RESPONSE_FIELDS = <<-GQL
    id
    statusCode
    roundtripTime
    length
    createdAt
    alteration
    edited
    GQL

  PAGE_INFO_FIELDS = <<-GQL
    pageInfo {
      hasNextPage
      hasPreviousPage
      startCursor
      endCursor
    }
    GQL

  module Requests
    # Get all requests with pagination
    def self.all(after : String? = nil, first : Int32? = 50, filter : String? = nil, last : Int32? = nil, before : String? = nil, scope_id : String? = nil, order : String? = nil, include_request_raw : Bool = false, include_response_raw : Bool = false)
      filter_clause = CaidoUtils.build_filter_clause(filter)
      pagination = CaidoUtils.build_pagination(after: after, first: first, before: before, last: last)

      args = [] of String
      args << pagination unless pagination.empty?
      args << filter_clause unless filter_clause.empty?
      args << %Q(scopeId: "#{CaidoUtils.escape_graphql_string(scope_id)}") if scope_id
      args << %Q(order: #{CaidoUtils.safe_enum_value(order)}) if order

      args_str = args.empty? ? "" : "(#{args.join(", ")})"
      request_raw_field = include_request_raw ? "raw" : ""
      response_raw_field = include_response_raw ? "raw" : ""

      %Q(
        query GetRequests {
          requests#{args_str} {
            #{PAGE_INFO_FIELDS}
            nodes {
              #{REQUEST_FIELDS}
              #{request_raw_field}
              response {
                #{RESPONSE_FIELDS}
                #{response_raw_field}
              }
            }
          }
        }
      )
    end

    # Get a single request by ID
    def self.by_id(id : String, include_request_raw : Bool = true, include_response_raw : Bool = true)
      escaped_id = CaidoUtils.escape_graphql_string(id)
      request_raw_field = include_request_raw ? "raw" : ""
      response_raw_field = include_response_raw ? "raw" : ""

      %Q(
        query GetRequest {
          request(id: "#{escaped_id}") {
            #{REQUEST_FIELDS}
            #{request_raw_field}
            response {
              #{RESPONSE_FIELDS}
              #{response_raw_field}
            }
          }
        }
      )
    end

    # Get requests by offset (alternative pagination)
    def self.by_offset(offset : Int32 = 0, limit : Int32 = 50, filter : String? = nil)
      filter_clause = CaidoUtils.build_filter_clause(filter)

      %Q(
        query GetRequestsByOffset {
          requestsByOffset(offset: #{offset} limit: #{limit} #{filter_clause}) {
            nodes {
              #{REQUEST_FIELDS}
            }
          }
        }
      )
    end
  end

  module Sitemap
    SITEMAP_ENTRY_FIELDS = <<-GQL
      id
      label
      kind
      parentId
      hasDescendants
      #{METADATA_FIELDS}
      GQL

    # Get root sitemap entries
    def self.root_entries(scope_id : String? = nil)
      scope_clause = scope_id ? %Q(scopeId: "#{CaidoUtils.escape_graphql_string(scope_id)}") : ""

      %Q(
        query GetSitemapRootEntries {
          sitemapRootEntries(#{scope_clause}) {
            nodes {
              #{SITEMAP_ENTRY_FIELDS}
            }
          }
        }
      )
    end

    # Get descendant entries of a parent
    def self.descendant_entries(parent_id : String, depth : String = "DIRECT")
      escaped_parent_id = CaidoUtils.escape_graphql_string(parent_id)
      %Q(
        query GetSitemapDescendantEntries {
          sitemapDescendantEntries(parentId: "#{escaped_parent_id}", depth: #{CaidoUtils.safe_enum_value(depth)}) {
            nodes {
              #{SITEMAP_ENTRY_FIELDS}
            }
          }
        }
      )
    end

    # Get a single sitemap entry
    def self.by_id(id : String)
      escaped_id = CaidoUtils.escape_graphql_string(id)
      %Q(
        query GetSitemapEntry {
          sitemapEntry(id: "#{escaped_id}") {
            #{SITEMAP_ENTRY_FIELDS}
          }
        }
      )
    end
  end

  module Intercept
    # Get intercept entries
    def self.entries(after : String? = nil, first : Int32 = 50, filter : String? = nil)
      filter_clause = CaidoUtils.build_filter_clause(filter)
      pagination = CaidoUtils.build_pagination(after: after, first: first)

      %Q(
        query GetInterceptEntries {
          interceptEntries(#{pagination} #{filter_clause}) {
            #{PAGE_INFO_FIELDS}
            nodes {
              id
              kind
              request {
                id
                host
                port
                path
                query
                method
                isTls
              }
            }
          }
        }
      )
    end

    # Get intercept status
    def self.status
      %Q(
        query GetInterceptStatus {
          interceptStatus {
            isEnabled
            inScopeOnly
          }
        }
      )
    end

    # Get intercept options
    def self.options
      %Q(
        query GetInterceptOptions {
          interceptOptions {
            request {
              enabled
              internal
              inScopeOnly
              query
            }
            response {
              enabled
              inScopeOnly
              statusCode {
                enabled
                value
              }
            }
          }
        }
      )
    end
  end

  module Scopes
    # Get all scopes
    def self.all
      %Q(
        query GetScopes {
          scopes {
            id
            name
            allowlist
            denylist
            indexed
          }
        }
      )
    end

    # Get a single scope
    def self.by_id(id : String)
      escaped_id = CaidoUtils.escape_graphql_string(id)
      %Q(
        query GetScope {
          scope(id: "#{escaped_id}") {
            id
            name
            allowlist
            denylist
            indexed
          }
        }
      )
    end
  end

  module Findings
    # Get findings with pagination
    def self.all(after : String? = nil, first : Int32 = 50, filter : String? = nil)
      pagination = CaidoUtils.build_pagination(after: after, first: first)
      filter_clause = filter ? %Q(filter: { reporter: "#{CaidoUtils.escape_graphql_string(filter)}" }) : ""

      %Q(
        query GetFindings {
          findings(#{pagination} #{filter_clause}) {
            #{PAGE_INFO_FIELDS}
            edges {
              cursor
              node {
                id
                title
                description
                reporter
                dedupeKey
                host
                path
                hidden
                createdAt
                request {
                  id
                }
              }
            }
          }
        }
      )
    end

    # Get a single finding
    def self.by_id(id : String)
      escaped_id = CaidoUtils.escape_graphql_string(id)
      %Q(
        query GetFinding {
          finding(id: "#{escaped_id}") {
            id
            title
            description
            reporter
            dedupeKey
            host
            path
            hidden
            createdAt
            request {
              id
            }
          }
        }
      )
    end

    # Get finding reporters
    def self.reporters
      %Q(
        query GetFindingReporters {
          findingReporters
        }
      )
    end
  end

  module Projects
    # Get current project
    def self.current
      %Q(
        query GetCurrentProject {
          currentProject {
            id
            name
            path
            version
            status
            size
            temporary
            readOnly
            createdAt
            updatedAt
            backups {
              id
              name
              path
              size
              createdAt
            }
          }
        }
      )
    end

    # Get all projects
    def self.all
      %Q(
        query GetProjects {
          projects {
            id
            name
            path
            version
            status
            size
            temporary
            readOnly
            createdAt
            updatedAt
          }
        }
      )
    end
  end

  module Workflows
    # Get all workflows
    def self.all
      %Q(
        query GetWorkflows {
          workflows {
            id
            name
            kind
            enabled
            global
            definition
            readOnly
            createdAt
            updatedAt
          }
        }
      )
    end

    # Get a single workflow
    def self.by_id(id : String)
      escaped_id = CaidoUtils.escape_graphql_string(id)
      %Q(
        query GetWorkflow {
          workflow(id: "#{escaped_id}") {
            id
            name
            kind
            enabled
            global
            definition
            readOnly
            createdAt
            updatedAt
          }
        }
      )
    end

    # Get workflow node definitions
    def self.node_definitions
      %Q(
        query GetWorkflowNodeDefinitions {
          workflowNodeDefinitions {
            id
            name
            kind
            body
          }
        }
      )
    end
  end

  module Replay
    # Get replay sessions
    def self.sessions(after : String? = nil, first : Int32 = 50)
      pagination = CaidoUtils.build_pagination(after: after, first: first)

      %Q(
        query GetReplaySessions {
          replaySessions(#{pagination}) {
            #{PAGE_INFO_FIELDS}
            nodes {
              id
              name
              activeEntry {
                id
              }
              collection {
                id
                name
              }
            }
          }
        }
      )
    end

    # Get a single replay session
    def self.session_by_id(id : String)
      escaped_id = CaidoUtils.escape_graphql_string(id)
      %Q(
        query GetReplaySession {
          replaySession(id: "#{escaped_id}") {
            id
            name
            activeEntry {
              id
              error
              request {
                id
                raw
              }
              response {
                id
                raw
              }
            }
            collection {
              id
              name
            }
          }
        }
      )
    end

    # Get a single replay entry by ID
    def self.entry_by_id(id : String, include_replay_raw : Bool = true, include_request_raw : Bool = true, include_response_raw : Bool = true)
      escaped_id = CaidoUtils.escape_graphql_string(id)
      replay_raw_field = include_replay_raw ? "raw" : ""
      request_raw_field = include_request_raw ? "raw" : ""
      response_raw_field = include_response_raw ? "raw" : ""

      %Q(
        query GetReplayEntry {
          replayEntry(id: "#{escaped_id}") {
            id
            createdAt
            error
            #{replay_raw_field}
            connection {
              host
              port
              isTLS
            }
            request {
              id
              host
              port
              method
              path
              query
              isTls
              createdAt
              #{request_raw_field}
              response {
                id
                statusCode
                roundtripTime
                length
                createdAt
                #{response_raw_field}
              }
            }
            session {
              id
            }
            settings {
              connectionClose
              updateContentLength
            }
          }
        }
      )
    end

    # Get entries for a replay session
    def self.session_entries(session_id : String, after : String? = nil, first : Int32 = 50, include_replay_raw : Bool = false, include_request_raw : Bool = false, include_response_raw : Bool = false)
      escaped_id = CaidoUtils.escape_graphql_string(session_id)
      pagination = CaidoUtils.build_pagination(after: after, first: first)
      replay_raw_field = include_replay_raw ? "raw" : ""
      request_raw_field = include_request_raw ? "raw" : ""
      response_raw_field = include_response_raw ? "raw" : ""

      %Q(
        query GetReplaySessionEntries {
          replaySession(id: "#{escaped_id}") {
            entries(#{pagination}) {
              #{PAGE_INFO_FIELDS}
              edges {
                cursor
                node {
                  id
                  createdAt
                  error
                  #{replay_raw_field}
                  connection {
                    host
                    port
                    isTLS
                  }
                  request {
                    id
                    host
                    port
                    method
                    path
                    query
                    isTls
                    createdAt
                    #{request_raw_field}
                    response {
                      id
                      statusCode
                      roundtripTime
                      length
                      createdAt
                      #{response_raw_field}
                    }
                  }
                  session {
                    id
                  }
                  settings {
                    connectionClose
                    updateContentLength
                  }
                }
              }
            }
          }
        }
      )
    end

    # Get replay session collections
    def self.collections(after : String? = nil, first : Int32 = 50)
      pagination = CaidoUtils.build_pagination(after: after, first: first)

      %Q(
        query GetReplaySessionCollections {
          replaySessionCollections(#{pagination}) {
            #{PAGE_INFO_FIELDS}
            nodes {
              id
              name
            }
          }
        }
      )
    end
  end

  module Automate
    # Get automate sessions
    def self.sessions(after : String? = nil, first : Int32 = 50)
      pagination = CaidoUtils.build_pagination(after: after, first: first)

      %Q(
        query GetAutomateSessions {
          automateSessions(#{pagination}) {
            #{PAGE_INFO_FIELDS}
            nodes {
              id
              name
              connection {
                host
                port
                isTls
              }
              createdAt
            }
          }
        }
      )
    end

    # Get a single automate session
    def self.session_by_id(id : String)
      escaped_id = CaidoUtils.escape_graphql_string(id)
      %Q(
        query GetAutomateSession {
          automateSession(id: "#{escaped_id}") {
            id
            name
            connection {
              host
              port
              isTls
            }
            settings {
              updateContentLength
              updateHostHeader
              followRedirects
              maxRedirects
            }
            createdAt
          }
        }
      )
    end

    # Get automate tasks
    def self.tasks(after : String? = nil, first : Int32 = 50)
      pagination = CaidoUtils.build_pagination(after: after, first: first)

      %Q(
        query GetAutomateTasks {
          automateTasks(#{pagination}) {
            #{PAGE_INFO_FIELDS}
            nodes {
              id
              paused
              createdAt
            }
          }
        }
      )
    end
  end

  module Viewer
    # Get current user information
    def self.info
      %Q(
        query GetViewer {
          viewer {
            ... on CloudUser {
              __typename
              id
              profile {
                identity {
                  email
                  name
                }
                subscription {
                  plan {
                    name
                  }
                  entitlements {
                    name
                  }
                }
              }
            }
            ... on GuestUser {
              __typename
              id
            }
            ... on ScriptUser {
              __typename
              id
            }
          }
        }
      )
    end
  end

  module Runtime
    # Get runtime information
    def self.info
      %Q(
        query GetRuntime {
          runtime {
            version
            platform
            availableUpdate
            supportedQueries
          }
        }
      )
    end
  end

  module InstanceSettings
    # Get instance settings
    def self.get
      %Q(
        query GetInstanceSettings {
          instanceSettings {
            aiProviders {
              anthropic {
                apiKey
              }
              google {
                apiKey
              }
              openai {
                apiKey
                url
              }
              openrouter {
                apiKey
              }
            }
            analytic {
              enabled
              cloud
              local
            }
            onboarding {
              analytic
            }
          }
        }
      )
    end
  end

  module DNS
    # Get DNS rewrites
    def self.rewrites
      %Q(
        query GetDNSRewrites {
          dnsRewrites {
            id
            enabled
            rank
            name
            strategy
            source
            destination
          }
        }
      )
    end

    # Get DNS upstreams
    def self.upstreams
      %Q(
        query GetDNSUpstreams {
          dnsUpstreams {
            id
            name
            kind
            address
          }
        }
      )
    end
  end

  module UpstreamProxies
    # Get HTTP upstream proxies
    def self.http
      %Q(
        query GetUpstreamProxiesHttp {
          upstreamProxiesHttp {
            id
            enabled
            rank
            allowlist
            denylist
            kind
            address
            authentication {
              username
              password
            }
          }
        }
      )
    end

    # Get SOCKS upstream proxies
    def self.socks
      %Q(
        query GetUpstreamProxiesSocks {
          upstreamProxiesSocks {
            id
            enabled
            rank
            allowlist
            denylist
            kind
            address
            authentication {
              username
              password
            }
          }
        }
      )
    end
  end

  module MatchReplace
    # Get all matchReplace rules
    def self.rules
      %Q(
        query GetMatchReplaceRules {
          matchReplaceRuleCollections {
            id
            name
            rules {
              id
              name
              enabled
              rank
              condition
              strategy
            }
          }
        }
      )
    end

    # Get a single matchReplace rule
    def self.rule_by_id(id : String)
      escaped_id = CaidoUtils.escape_graphql_string(id)
      %Q(
        query GetMatchReplaceRule {
          matchReplaceRule(id: "#{escaped_id}") {
            id
            name
            enabled
            rank
            condition
            strategy
            collection {
              id
              name
            }
          }
        }
      )
    end
  end

  module Assistant
    # Get assistant sessions (requires cloud)
    def self.sessions
      %Q(
        query GetAssistantSessions {
          assistantSessions {
            id
            name
            modelId
            createdAt
          }
        }
      )
    end

    # Get assistant models (requires cloud)
    def self.models
      %Q(
        query GetAssistantModels {
          assistantModels {
            id
            name
            provider
          }
        }
      )
    end
  end

  module Environments
    # Get all environments
    def self.all
      %Q(
        query GetEnvironments {
          environments {
            id
            name
            variables {
              name
              value
              kind
            }
            version
          }
        }
      )
    end

    # Get a single environment by ID
    def self.by_id(id : String)
      escaped_id = CaidoUtils.escape_graphql_string(id)
      %Q(
        query GetEnvironment {
          environment(id: "#{escaped_id}") {
            id
            name
            variables {
              name
              value
              kind
            }
            version
          }
        }
      )
    end

    # Get environment context
    def self.context
      %Q(
        query GetEnvironmentContext {
          environmentContext {
            selectedId
          }
        }
      )
    end
  end

  module Plugins
    # Get all plugin packages
    def self.packages
      %Q(
        query GetPluginPackages {
          pluginPackages {
            id
            manifestId
            plugins {
              __typename
              id
              manifestId
              enabled
            }
          }
        }
      )
    end
  end

  module FilterPresets
    # Get all filter presets
    def self.all
      %Q(
        query GetFilterPresets {
          filterPresets {
            id
            name
            alias
            clause
          }
        }
      )
    end

    # Get a single filter preset by ID
    def self.by_id(id : String)
      escaped_id = CaidoUtils.escape_graphql_string(id)
      %Q(
        query GetFilterPreset {
          filterPreset(id: "#{escaped_id}") {
            id
            name
            alias
            clause
          }
        }
      )
    end
  end

  module HostedFiles
    # Get all hosted files
    def self.all
      %Q(
        query GetHostedFiles {
          hostedFiles {
            id
            name
            path
            size
            status
            createdAt
            updatedAt
          }
        }
      )
    end
  end

  module Tasks
    # Get all tasks
    def self.all
      %Q(
        query GetTasks {
          tasks {
            __typename
            id
            createdAt
            ... on ReplayTask {
              replayEntry {
                id
              }
            }
          }
        }
      )
    end
  end

  module Responses
    # Get a single response by ID
    def self.by_id(id : String)
      escaped_id = CaidoUtils.escape_graphql_string(id)
      %Q(
        query GetResponse {
          response(id: "#{escaped_id}") {
            id
            statusCode
            roundtripTime
            length
            createdAt
            raw
          }
        }
      )
    end
  end
end
