require "./utils"

module CaidoQueries
  # Query templates for common Caido GraphQL operations

  module Requests
    # Get all requests with pagination
    def self.all(after : String? = nil, first : Int32 = 50, filter : String? = nil)
      filter_clause = CaidoUtils.build_filter_clause(filter)
      after_clause = after ? %Q(after: "#{CaidoUtils.escape_graphql_string(after)}") : ""
      
      %Q(
        query GetRequests {
          requests(#{after_clause} first: #{first} #{filter_clause}) {
            pageInfo {
              hasNextPage
              hasPreviousPage
              startCursor
              endCursor
            }
            nodes {
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
              metadata {
                id
                color
                label
              }
              fileExtension
              source
              createdAt
              response {
                id
                statusCode
                roundtripTime
                length
                createdAt
                alteration
                edited
              }
            }
          }
        }
      )
    end

    # Get a single request by ID
    def self.by_id(id : String)
      escaped_id = CaidoUtils.escape_graphql_string(id)
      %Q(
        query GetRequest {
          request(id: "#{escaped_id}") {
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
            metadata {
              id
              color
              label
            }
            fileExtension
            source
            createdAt
            raw
            response {
              id
              statusCode
              roundtripTime
              length
              createdAt
              alteration
              edited
              raw
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
              metadata {
                id
                color
                label
              }
              fileExtension
              source
              createdAt
            }
          }
        }
      )
    end
  end

  module Sitemap
    # Get root sitemap entries
    def self.root_entries(scope_id : String? = nil)
      scope_clause = scope_id ? %Q(scopeId: "#{CaidoUtils.escape_graphql_string(scope_id)}") : ""
      
      %Q(
        query GetSitemapRootEntries {
          sitemapRootEntries(#{scope_clause}) {
            nodes {
              id
              label
              kind
              parentId
              hasDescendants
              metadata {
                id
                color
                label
              }
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
          sitemapDescendantEntries(parentId: "#{escaped_parent_id}", depth: #{depth}) {
            nodes {
              id
              label
              kind
              parentId
              hasDescendants
              metadata {
                id
                color
                label
              }
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
            id
            label
            kind
            parentId
            hasDescendants
            metadata {
              id
              color
              label
            }
          }
        }
      )
    end
  end

  module Intercept
    # Get intercept entries
    def self.entries(after : String? = nil, first : Int32 = 50, filter : String? = nil)
      filter_clause = CaidoUtils.build_filter_clause(filter)
      after_clause = after ? %Q(after: "#{CaidoUtils.escape_graphql_string(after)}") : ""
      
      %Q(
        query GetInterceptEntries {
          interceptEntries(#{after_clause} first: #{first} #{filter_clause}) {
            pageInfo {
              hasNextPage
              hasPreviousPage
              startCursor
              endCursor
            }
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
          }
        }
      )
    end
  end

  module Findings
    # Get findings with pagination
    def self.all(after : String? = nil, first : Int32 = 50)
      after_clause = after ? %Q(after: "#{CaidoUtils.escape_graphql_string(after)}") : ""
      
      %Q(
        query GetFindings {
          findings(#{after_clause} first: #{first}) {
            pageInfo {
              hasNextPage
              hasPreviousPage
              startCursor
              endCursor
            }
            nodes {
              id
              title
              description
              reporter
              dedupeKey
              createdAt
              request {
                id
                host
                path
                method
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
            createdAt
            request {
              id
              host
              path
              query
              method
              raw
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

    # Get all projects (requires cloud)
    def self.all
      %Q(
        query GetProjects {
          projects {
            id
            name
            path
            version
            status
            createdAt
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
      after_clause = after ? %Q(after: "#{CaidoUtils.escape_graphql_string(after)}") : ""
      
      %Q(
        query GetReplaySessions {
          replaySessions(#{after_clause} first: #{first}) {
            pageInfo {
              hasNextPage
              hasPreviousPage
              startCursor
              endCursor
            }
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

    # Get replay session collections
    def self.collections(after : String? = nil, first : Int32 = 50)
      after_clause = after ? %Q(after: "#{CaidoUtils.escape_graphql_string(after)}") : ""
      
      %Q(
        query GetReplaySessionCollections {
          replaySessionCollections(#{after_clause} first: #{first}) {
            pageInfo {
              hasNextPage
              hasPreviousPage
              startCursor
              endCursor
            }
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
      after_clause = after ? %Q(after: "#{CaidoUtils.escape_graphql_string(after)}") : ""
      
      %Q(
        query GetAutomateSessions {
          automateSessions(#{after_clause} first: #{first}) {
            pageInfo {
              hasNextPage
              hasPreviousPage
              startCursor
              endCursor
            }
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
      after_clause = after ? %Q(after: "#{CaidoUtils.escape_graphql_string(after)}") : ""
      
      %Q(
        query GetAutomateTasks {
          automateTasks(#{after_clause} first: #{first}) {
            pageInfo {
              hasNextPage
              hasPreviousPage
              startCursor
              endCursor
            }
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
            id
            username
            settings {
              data
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
            theme
            language
            license {
              name
              expiry
            }
            ai {
              providers {
                anthropic {
                  apiKey
                }
                openai {
                  apiKey
                  url
                }
                google {
                  apiKey
                }
                openrouter {
                  apiKey
                }
              }
              model
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

  module Tamper
    # Get all tamper rules
    def self.rules
      %Q(
        query GetTamperRules {
          tamperRuleCollections {
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

    # Get a single tamper rule
    def self.rule_by_id(id : String)
      escaped_id = CaidoUtils.escape_graphql_string(id)
      %Q(
        query GetTamperRule {
          tamperRule(id: "#{escaped_id}") {
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
    # Get all environments (requires cloud)
    def self.all
      %Q(
        query GetEnvironments {
          environments {
            id
            name
            data
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
            name
            version
            author
            description
            enabled
          }
        }
      )
    end
  end
end
