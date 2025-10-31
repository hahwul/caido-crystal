module CaidoMutations
  # Mutation templates for common Caido GraphQL operations

  module Requests
    # Update request metadata (color, label)
    def self.update_metadata(request_id : String, color : String? = nil, label : String? = nil)
      metadata_parts = [] of String
      metadata_parts << %Q(color: "#{color}") if color
      metadata_parts << %Q(label: "#{label}") if label
      metadata_input = metadata_parts.join(", ")
      
      %Q(
        mutation UpdateRequestMetadata {
          updateRequestMetadata(id: "#{request_id}", input: { #{metadata_input} }) {
            request {
              id
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

    # Render a request with environment variables
    def self.render(request_id : String)
      %Q(
        mutation RenderRequest {
          renderRequest(id: "#{request_id}", input: {}) {
            request {
              id
              raw
            }
          }
        }
      )
    end
  end

  module Sitemap
    # Create sitemap entries from a request
    def self.create_entries(request_id : String)
      %Q(
        mutation CreateSitemapEntries {
          createSitemapEntries(requestId: "#{request_id}") {
            entries {
              id
              label
              kind
            }
          }
        }
      )
    end

    # Delete sitemap entries
    def self.delete_entries(entry_ids : Array(String))
      ids_str = entry_ids.map { |id| %Q("#{id}") }.join(", ")
      
      %Q(
        mutation DeleteSitemapEntries {
          deleteSitemapEntries(ids: [#{ids_str}]) {
            deletedIds
          }
        }
      )
    end

    # Clear all sitemap entries
    def self.clear_all
      %Q(
        mutation ClearSitemapEntries {
          clearSitemapEntries {
            success
          }
        }
      )
    end
  end

  module Intercept
    # Pause intercept
    def self.pause
      %Q(
        mutation PauseIntercept {
          pauseIntercept {
            success
          }
        }
      )
    end

    # Resume intercept
    def self.resume
      %Q(
        mutation ResumeIntercept {
          resumeIntercept {
            success
          }
        }
      )
    end

    # Forward an intercept message
    def self.forward_message(message_id : String, request : String? = nil, response : String? = nil)
      input_parts = [] of String
      input_parts << %Q(request: "#{request}") if request
      input_parts << %Q(response: "#{response}") if response
      input_str = input_parts.empty? ? "" : ", input: { #{input_parts.join(", ")} }"
      
      %Q(
        mutation ForwardInterceptMessage {
          forwardInterceptMessage(id: "#{message_id}"#{input_str}) {
            success
          }
        }
      )
    end

    # Drop an intercept message
    def self.drop_message(message_id : String)
      %Q(
        mutation DropInterceptMessage {
          dropInterceptMessage(id: "#{message_id}") {
            success
          }
        }
      )
    end

    # Set intercept options
    def self.set_options(request_enabled : Bool? = nil, response_enabled : Bool? = nil, in_scope_only : Bool? = nil)
      options = [] of String
      
      if request_enabled || in_scope_only
        req_parts = [] of String
        req_parts << "enabled: #{request_enabled}" if request_enabled
        req_parts << "inScopeOnly: #{in_scope_only}" if in_scope_only
        options << "request: { #{req_parts.join(", ")} }" unless req_parts.empty?
      end
      
      if response_enabled
        options << "response: { enabled: #{response_enabled} }"
      end
      
      %Q(
        mutation SetInterceptOptions {
          setInterceptOptions(input: { #{options.join(", ")} }) {
            options {
              request {
                enabled
                inScopeOnly
              }
              response {
                enabled
              }
            }
          }
        }
      )
    end

    # Delete intercept entries
    def self.delete_entries(filter : String? = nil)
      filter_clause = filter ? %Q(filter: "#{filter}") : ""
      
      %Q(
        mutation DeleteInterceptEntries {
          deleteInterceptEntries(#{filter_clause}) {
            deletedCount
          }
        }
      )
    end
  end

  module Scopes
    # Create a new scope
    def self.create(name : String, allowlist : Array(String), denylist : Array(String) = [] of String)
      allowlist_str = allowlist.map { |item| %Q("#{item}") }.join(", ")
      denylist_str = denylist.map { |item| %Q("#{item}") }.join(", ")
      
      %Q(
        mutation CreateScope {
          createScope(input: { 
            name: "#{name}", 
            allowlist: [#{allowlist_str}], 
            denylist: [#{denylist_str}] 
          }) {
            scope {
              id
              name
              allowlist
              denylist
            }
          }
        }
      )
    end

    # Update a scope
    def self.update(scope_id : String, name : String? = nil, allowlist : Array(String)? = nil, denylist : Array(String)? = nil)
      updates = [] of String
      updates << %Q(name: "#{name}") if name
      
      if allowlist
        allowlist_str = allowlist.map { |item| %Q("#{item}") }.join(", ")
        updates << %Q(allowlist: [#{allowlist_str}])
      end
      
      if denylist
        denylist_str = denylist.map { |item| %Q("#{item}") }.join(", ")
        updates << %Q(denylist: [#{denylist_str}])
      end
      
      %Q(
        mutation UpdateScope {
          updateScope(id: "#{scope_id}", input: { #{updates.join(", ")} }) {
            scope {
              id
              name
              allowlist
              denylist
            }
          }
        }
      )
    end

    # Delete a scope
    def self.delete(scope_id : String)
      %Q(
        mutation DeleteScope {
          deleteScope(id: "#{scope_id}") {
            deletedId
          }
        }
      )
    end

    # Rename a scope
    def self.rename(scope_id : String, name : String)
      %Q(
        mutation RenameScope {
          renameScope(id: "#{scope_id}", name: "#{name}") {
            scope {
              id
              name
            }
          }
        }
      )
    end
  end

  module Findings
    # Create a finding
    def self.create(request_id : String, title : String, description : String? = nil, reporter : String = "Manual")
      desc_clause = description ? %Q(description: "#{description}") : ""
      
      %Q(
        mutation CreateFinding {
          createFinding(requestId: "#{request_id}", input: { 
            title: "#{title}", 
            #{desc_clause}
            reporter: "#{reporter}" 
          }) {
            finding {
              id
              title
              description
              reporter
            }
          }
        }
      )
    end

    # Update a finding
    def self.update(finding_id : String, title : String? = nil, description : String? = nil)
      updates = [] of String
      updates << %Q(title: "#{title}") if title
      updates << %Q(description: "#{description}") if description
      
      %Q(
        mutation UpdateFinding {
          updateFinding(id: "#{finding_id}", input: { #{updates.join(", ")} }) {
            finding {
              id
              title
              description
            }
          }
        }
      )
    end

    # Delete findings
    def self.delete(finding_ids : Array(String)? = nil)
      ids_clause = if finding_ids
        ids_str = finding_ids.map { |id| %Q("#{id}") }.join(", ")
        %Q(input: { ids: [#{ids_str}] })
      else
        ""
      end
      
      %Q(
        mutation DeleteFindings {
          deleteFindings(#{ids_clause}) {
            deletedCount
          }
        }
      )
    end

    # Hide findings
    def self.hide(finding_ids : Array(String))
      ids_str = finding_ids.map { |id| %Q("#{id}") }.join(", ")
      
      %Q(
        mutation HideFindings {
          hideFindings(input: { ids: [#{ids_str}] }) {
            findings {
              id
            }
          }
        }
      )
    end

    # Export findings
    def self.export(finding_ids : Array(String)? = nil)
      ids_clause = if finding_ids
        ids_str = finding_ids.map { |id| %Q("#{id}") }.join(", ")
        %Q(ids: [#{ids_str}])
      else
        ""
      end
      
      %Q(
        mutation ExportFindings {
          exportFindings(input: { #{ids_clause} }) {
            export {
              id
              name
              path
            }
          }
        }
      )
    end
  end

  module Projects
    # Select a project (requires cloud)
    def self.select(project_id : String)
      %Q(
        mutation SelectProject {
          selectProject(id: "#{project_id}") {
            project {
              id
              name
              path
            }
          }
        }
      )
    end

    # Create a project (requires cloud)
    def self.create(name : String, path : String? = nil)
      path_clause = path ? %Q(path: "#{path}") : ""
      
      %Q(
        mutation CreateProject {
          createProject(input: { name: "#{name}", #{path_clause} }) {
            project {
              id
              name
              path
            }
          }
        }
      )
    end

    # Delete a project (requires cloud)
    def self.delete(project_id : String)
      %Q(
        mutation DeleteProject {
          deleteProject(id: "#{project_id}") {
            deletedId
          }
        }
      )
    end

    # Rename a project (requires cloud)
    def self.rename(project_id : String, name : String)
      %Q(
        mutation RenameProject {
          renameProject(id: "#{project_id}", name: "#{name}") {
            project {
              id
              name
            }
          }
        }
      )
    end
  end

  module Workflows
    # Create a workflow (requires cloud)
    def self.create(name : String, kind : String, definition : String)
      %Q(
        mutation CreateWorkflow {
          createWorkflow(input: { 
            name: "#{name}", 
            kind: #{kind}, 
            definition: "#{definition}" 
          }) {
            workflow {
              id
              name
              kind
              definition
            }
          }
        }
      )
    end

    # Update a workflow
    def self.update(workflow_id : String, name : String? = nil, definition : String? = nil)
      updates = [] of String
      updates << %Q(name: "#{name}") if name
      updates << %Q(definition: "#{definition}") if definition
      
      %Q(
        mutation UpdateWorkflow {
          updateWorkflow(id: "#{workflow_id}", input: { #{updates.join(", ")} }) {
            workflow {
              id
              name
              definition
            }
          }
        }
      )
    end

    # Delete a workflow
    def self.delete(workflow_id : String)
      %Q(
        mutation DeleteWorkflow {
          deleteWorkflow(id: "#{workflow_id}") {
            deletedId
          }
        }
      )
    end

    # Rename a workflow
    def self.rename(workflow_id : String, name : String)
      %Q(
        mutation RenameWorkflow {
          renameWorkflow(id: "#{workflow_id}", name: "#{name}") {
            workflow {
              id
              name
            }
          }
        }
      )
    end

    # Toggle workflow enabled state
    def self.toggle(workflow_id : String, enabled : Bool)
      %Q(
        mutation ToggleWorkflow {
          toggleWorkflow(id: "#{workflow_id}", enabled: #{enabled}) {
            workflow {
              id
              enabled
            }
          }
        }
      )
    end

    # Run an active workflow
    def self.run_active(workflow_id : String, request_id : String)
      %Q(
        mutation RunActiveWorkflow {
          runActiveWorkflow(id: "#{workflow_id}", input: { requestId: "#{request_id}" }) {
            result {
              __typename
            }
          }
        }
      )
    end
  end

  module Replay
    # Create a replay session
    def self.create_session(name : String, source : String, collection_id : String? = nil)
      collection_clause = collection_id ? %Q(collectionId: "#{collection_id}") : ""
      
      %Q(
        mutation CreateReplaySession {
          createReplaySession(input: { 
            name: "#{name}", 
            source: "#{source}", 
            #{collection_clause} 
          }) {
            session {
              id
              name
            }
          }
        }
      )
    end

    # Create a replay session collection
    def self.create_collection(name : String)
      %Q(
        mutation CreateReplaySessionCollection {
          createReplaySessionCollection(input: { name: "#{name}" }) {
            collection {
              id
              name
            }
          }
        }
      )
    end

    # Delete replay sessions
    def self.delete_sessions(session_ids : Array(String))
      ids_str = session_ids.map { |id| %Q("#{id}") }.join(", ")
      
      %Q(
        mutation DeleteReplaySessions {
          deleteReplaySessions(ids: [#{ids_str}]) {
            deletedIds
          }
        }
      )
    end

    # Delete a replay session collection
    def self.delete_collection(collection_id : String)
      %Q(
        mutation DeleteReplaySessionCollection {
          deleteReplaySessionCollection(id: "#{collection_id}") {
            deletedId
          }
        }
      )
    end

    # Rename a replay session
    def self.rename_session(session_id : String, name : String)
      %Q(
        mutation RenameReplaySession {
          renameReplaySession(id: "#{session_id}", name: "#{name}") {
            session {
              id
              name
            }
          }
        }
      )
    end

    # Rename a replay session collection
    def self.rename_collection(collection_id : String, name : String)
      %Q(
        mutation RenameReplaySessionCollection {
          renameReplaySessionCollection(id: "#{collection_id}", name: "#{name}") {
            collection {
              id
              name
            }
          }
        }
      )
    end

    # Move a replay session to a collection
    def self.move_session(session_id : String, collection_id : String)
      %Q(
        mutation MoveReplaySession {
          moveReplaySession(id: "#{session_id}", collectionId: "#{collection_id}") {
            session {
              id
              collection {
                id
                name
              }
            }
          }
        }
      )
    end

    # Start a replay task (requires cloud)
    def self.start_task(session_id : String)
      %Q(
        mutation StartReplayTask {
          startReplayTask(sessionId: "#{session_id}", input: {}) {
            task {
              id
            }
          }
        }
      )
    end
  end

  module Automate
    # Create an automate session
    def self.create_session(name : String, host : String, port : Int32, is_tls : Bool = false)
      %Q(
        mutation CreateAutomateSession {
          createAutomateSession(input: { 
            name: "#{name}", 
            connection: { 
              host: "#{host}", 
              port: #{port}, 
              isTls: #{is_tls} 
            } 
          }) {
            session {
              id
              name
              connection {
                host
                port
                isTls
              }
            }
          }
        }
      )
    end

    # Delete an automate session
    def self.delete_session(session_id : String)
      %Q(
        mutation DeleteAutomateSession {
          deleteAutomateSession(id: "#{session_id}") {
            deletedId
          }
        }
      )
    end

    # Rename an automate session
    def self.rename_session(session_id : String, name : String)
      %Q(
        mutation RenameAutomateSession {
          renameAutomateSession(id: "#{session_id}", name: "#{name}") {
            session {
              id
              name
            }
          }
        }
      )
    end

    # Duplicate an automate session
    def self.duplicate_session(session_id : String)
      %Q(
        mutation DuplicateAutomateSession {
          duplicateAutomateSession(id: "#{session_id}") {
            session {
              id
              name
            }
          }
        }
      )
    end

    # Start an automate task
    def self.start_task(session_id : String)
      %Q(
        mutation StartAutomateTask {
          startAutomateTask(automateSessionId: "#{session_id}") {
            task {
              id
            }
          }
        }
      )
    end

    # Pause an automate task
    def self.pause_task(task_id : String)
      %Q(
        mutation PauseAutomateTask {
          pauseAutomateTask(id: "#{task_id}") {
            task {
              id
              paused
            }
          }
        }
      )
    end

    # Resume an automate task
    def self.resume_task(task_id : String)
      %Q(
        mutation ResumeAutomateTask {
          resumeAutomateTask(id: "#{task_id}") {
            task {
              id
              paused
            }
          }
        }
      )
    end

    # Cancel an automate task
    def self.cancel_task(task_id : String)
      %Q(
        mutation CancelAutomateTask {
          cancelAutomateTask(id: "#{task_id}") {
            success
          }
        }
      )
    end

    # Delete automate entries
    def self.delete_entries(entry_ids : Array(String))
      ids_str = entry_ids.map { |id| %Q("#{id}") }.join(", ")
      
      %Q(
        mutation DeleteAutomateEntries {
          deleteAutomateEntries(ids: [#{ids_str}]) {
            deletedIds
          }
        }
      )
    end
  end

  module Tamper
    # Create a tamper rule
    def self.create_rule(name : String, condition : String, strategy : String, collection_id : String? = nil)
      collection_clause = collection_id ? %Q(collectionId: "#{collection_id}") : ""
      
      %Q(
        mutation CreateTamperRule {
          createTamperRule(input: { 
            name: "#{name}", 
            condition: "#{condition}", 
            strategy: "#{strategy}", 
            #{collection_clause} 
          }) {
            rule {
              id
              name
              enabled
              condition
              strategy
            }
          }
        }
      )
    end

    # Create a tamper rule collection
    def self.create_collection(name : String)
      %Q(
        mutation CreateTamperRuleCollection {
          createTamperRuleCollection(input: { name: "#{name}" }) {
            collection {
              id
              name
            }
          }
        }
      )
    end

    # Update a tamper rule
    def self.update_rule(rule_id : String, name : String? = nil, condition : String? = nil, strategy : String? = nil)
      updates = [] of String
      updates << %Q(name: "#{name}") if name
      updates << %Q(condition: "#{condition}") if condition
      updates << %Q(strategy: "#{strategy}") if strategy
      
      %Q(
        mutation UpdateTamperRule {
          updateTamperRule(id: "#{rule_id}", input: { #{updates.join(", ")} }) {
            rule {
              id
              name
              condition
              strategy
            }
          }
        }
      )
    end

    # Delete a tamper rule
    def self.delete_rule(rule_id : String)
      %Q(
        mutation DeleteTamperRule {
          deleteTamperRule(id: "#{rule_id}") {
            deletedId
          }
        }
      )
    end

    # Delete a tamper rule collection
    def self.delete_collection(collection_id : String)
      %Q(
        mutation DeleteTamperRuleCollection {
          deleteTamperRuleCollection(id: "#{collection_id}") {
            deletedId
          }
        }
      )
    end

    # Toggle tamper rule enabled state
    def self.toggle_rule(rule_id : String, enabled : Bool)
      %Q(
        mutation ToggleTamperRule {
          toggleTamperRule(id: "#{rule_id}", enabled: #{enabled}) {
            rule {
              id
              enabled
            }
          }
        }
      )
    end

    # Rename a tamper rule
    def self.rename_rule(rule_id : String, name : String)
      %Q(
        mutation RenameTamperRule {
          renameTamperRule(id: "#{rule_id}", name: "#{name}") {
            rule {
              id
              name
            }
          }
        }
      )
    end

    # Rename a tamper rule collection
    def self.rename_collection(collection_id : String, name : String)
      %Q(
        mutation RenameTamperRuleCollection {
          renameTamperRuleCollection(id: "#{collection_id}", name: "#{name}") {
            collection {
              id
              name
            }
          }
        }
      )
    end

    # Move a tamper rule to a collection
    def self.move_rule(rule_id : String, collection_id : String)
      %Q(
        mutation MoveTamperRule {
          moveTamperRule(id: "#{rule_id}", collectionId: "#{collection_id}") {
            rule {
              id
              collection {
                id
                name
              }
            }
          }
        }
      )
    end
  end

  module DNS
    # Create a DNS rewrite
    def self.create_rewrite(name : String, strategy : String, source : String, destination : String)
      %Q(
        mutation CreateDNSRewrite {
          createDnsRewrite(input: { 
            name: "#{name}", 
            strategy: #{strategy}, 
            source: "#{source}", 
            destination: "#{destination}" 
          }) {
            rewrite {
              id
              name
              enabled
              strategy
              source
              destination
            }
          }
        }
      )
    end

    # Update a DNS rewrite
    def self.update_rewrite(rewrite_id : String, name : String? = nil, strategy : String? = nil, source : String? = nil, destination : String? = nil)
      updates = [] of String
      updates << %Q(name: "#{name}") if name
      updates << %Q(strategy: #{strategy}) if strategy
      updates << %Q(source: "#{source}") if source
      updates << %Q(destination: "#{destination}") if destination
      
      %Q(
        mutation UpdateDNSRewrite {
          updateDnsRewrite(id: "#{rewrite_id}", input: { #{updates.join(", ")} }) {
            rewrite {
              id
              name
              strategy
              source
              destination
            }
          }
        }
      )
    end

    # Delete a DNS rewrite
    def self.delete_rewrite(rewrite_id : String)
      %Q(
        mutation DeleteDNSRewrite {
          deleteDnsRewrite(id: "#{rewrite_id}") {
            deletedId
          }
        }
      )
    end

    # Toggle DNS rewrite enabled state
    def self.toggle_rewrite(rewrite_id : String, enabled : Bool)
      %Q(
        mutation ToggleDNSRewrite {
          toggleDnsRewrite(id: "#{rewrite_id}", enabled: #{enabled}) {
            rewrite {
              id
              enabled
            }
          }
        }
      )
    end

    # Create a DNS upstream
    def self.create_upstream(name : String, kind : String, address : String)
      %Q(
        mutation CreateDNSUpstream {
          createDnsUpstream(input: { 
            name: "#{name}", 
            kind: #{kind}, 
            address: "#{address}" 
          }) {
            upstream {
              id
              name
              kind
              address
            }
          }
        }
      )
    end

    # Update a DNS upstream
    def self.update_upstream(upstream_id : String, name : String? = nil, kind : String? = nil, address : String? = nil)
      updates = [] of String
      updates << %Q(name: "#{name}") if name
      updates << %Q(kind: #{kind}) if kind
      updates << %Q(address: "#{address}") if address
      
      %Q(
        mutation UpdateDNSUpstream {
          updateDnsUpstream(id: "#{upstream_id}", input: { #{updates.join(", ")} }) {
            upstream {
              id
              name
              kind
              address
            }
          }
        }
      )
    end

    # Delete a DNS upstream
    def self.delete_upstream(upstream_id : String)
      %Q(
        mutation DeleteDNSUpstream {
          deleteDnsUpstream(id: "#{upstream_id}") {
            deletedId
          }
        }
      )
    end
  end

  module UpstreamProxies
    # Create an HTTP upstream proxy
    def self.create_http(kind : String, address : String, allowlist : Array(String) = [] of String, denylist : Array(String) = [] of String)
      allowlist_str = allowlist.map { |item| %Q("#{item}") }.join(", ")
      denylist_str = denylist.map { |item| %Q("#{item}") }.join(", ")
      
      %Q(
        mutation CreateUpstreamProxyHttp {
          createUpstreamProxyHttp(input: { 
            kind: #{kind}, 
            address: "#{address}", 
            allowlist: [#{allowlist_str}], 
            denylist: [#{denylist_str}] 
          }) {
            proxy {
              id
              kind
              address
              enabled
            }
          }
        }
      )
    end

    # Create a SOCKS upstream proxy
    def self.create_socks(kind : String, address : String, allowlist : Array(String) = [] of String, denylist : Array(String) = [] of String)
      allowlist_str = allowlist.map { |item| %Q("#{item}") }.join(", ")
      denylist_str = denylist.map { |item| %Q("#{item}") }.join(", ")
      
      %Q(
        mutation CreateUpstreamProxySocks {
          createUpstreamProxySocks(input: { 
            kind: #{kind}, 
            address: "#{address}", 
            allowlist: [#{allowlist_str}], 
            denylist: [#{denylist_str}] 
          }) {
            proxy {
              id
              kind
              address
              enabled
            }
          }
        }
      )
    end

    # Delete an HTTP upstream proxy
    def self.delete_http(proxy_id : String)
      %Q(
        mutation DeleteUpstreamProxyHttp {
          deleteUpstreamProxyHttp(id: "#{proxy_id}") {
            deletedId
          }
        }
      )
    end

    # Delete a SOCKS upstream proxy
    def self.delete_socks(proxy_id : String)
      %Q(
        mutation DeleteUpstreamProxySocks {
          deleteUpstreamProxySocks(id: "#{proxy_id}") {
            deletedId
          }
        }
      )
    end

    # Toggle HTTP upstream proxy enabled state
    def self.toggle_http(proxy_id : String, enabled : Bool)
      %Q(
        mutation ToggleUpstreamProxyHttp {
          toggleUpstreamProxyHttp(id: "#{proxy_id}", enabled: #{enabled}) {
            proxy {
              id
              enabled
            }
          }
        }
      )
    end

    # Toggle SOCKS upstream proxy enabled state
    def self.toggle_socks(proxy_id : String, enabled : Bool)
      %Q(
        mutation ToggleUpstreamProxySocks {
          toggleUpstreamProxySocks(id: "#{proxy_id}", enabled: #{enabled}) {
            proxy {
              id
              enabled
            }
          }
        }
      )
    end
  end

  module Assistant
    # Create an assistant session (requires cloud)
    def self.create_session(model_id : String, name : String? = nil)
      name_clause = name ? %Q(name: "#{name}") : ""
      
      %Q(
        mutation CreateAssistantSession {
          createAssistantSession(input: { modelId: "#{model_id}", #{name_clause} }) {
            session {
              id
              name
              modelId
            }
          }
        }
      )
    end

    # Delete an assistant session
    def self.delete_session(session_id : String)
      %Q(
        mutation DeleteAssistantSession {
          deleteAssistantSession(id: "#{session_id}") {
            deletedId
          }
        }
      )
    end

    # Rename an assistant session
    def self.rename_session(session_id : String, name : String)
      %Q(
        mutation RenameAssistantSession {
          renameAssistantSession(id: "#{session_id}", name: "#{name}") {
            session {
              id
              name
            }
          }
        }
      )
    end

    # Send a message to the assistant (requires cloud)
    def self.send_message(session_id : String, message : String)
      %Q(
        mutation SendAssistantMessage {
          sendAssistantMessage(sessionId: "#{session_id}", message: "#{message}") {
            message {
              id
              role
              content
            }
          }
        }
      )
    end
  end

  module Authentication
    # Start authentication flow (requires cloud)
    def self.start_flow
      %Q(
        mutation StartAuthenticationFlow {
          startAuthenticationFlow {
            requestId
          }
        }
      )
    end

    # Login as guest (requires cloud)
    def self.login_guest
      %Q(
        mutation LoginAsGuest {
          loginAsGuest {
            authenticationToken
            refreshToken
          }
        }
      )
    end

    # Logout (requires cloud)
    def self.logout
      %Q(
        mutation Logout {
          logout {
            success
          }
        }
      )
    end
  end

  module Tasks
    # Cancel a task
    def self.cancel(task_id : String)
      %Q(
        mutation CancelTask {
          cancelTask(id: "#{task_id}") {
            success
          }
        }
      )
    end
  end
end
