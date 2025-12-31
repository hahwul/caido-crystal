require "./utils"

module CaidoMutations
  # Mutation templates for common Caido GraphQL operations

  module Requests
    # Update request metadata (color, label)
    def self.update_metadata(request_id : String, color : String? = nil, label : String? = nil)
      escaped_id = CaidoUtils.escape_graphql_string(request_id)
      metadata_parts = [] of String
      metadata_parts << %Q(color: "#{CaidoUtils.escape_graphql_string(color.not_nil!)}") if color
      metadata_parts << %Q(label: "#{CaidoUtils.escape_graphql_string(label.not_nil!)}") if label
      metadata_input = metadata_parts.join(", ")
      
      %Q(
        mutation UpdateRequestMetadata {
          updateRequestMetadata(id: "#{escaped_id}", input: { #{metadata_input} }) {
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
      escaped_id = CaidoUtils.escape_graphql_string(request_id)
      %Q(
        mutation RenderRequest {
          renderRequest(id: "#{escaped_id}", input: {}) {
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
      escaped_id = CaidoUtils.escape_graphql_string(request_id)
      %Q(
        mutation CreateSitemapEntries {
          createSitemapEntries(requestId: "#{escaped_id}") {
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
      ids_str = CaidoUtils.build_string_array(entry_ids)
      
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
      escaped_id = CaidoUtils.escape_graphql_string(message_id)
      input_parts = [] of String
      input_parts << %Q(request: "#{CaidoUtils.escape_graphql_string(request.not_nil!)}") if request
      input_parts << %Q(response: "#{CaidoUtils.escape_graphql_string(response.not_nil!)}") if response
      input_str = input_parts.empty? ? "" : ", input: { #{input_parts.join(", ")} }"
      
      %Q(
        mutation ForwardInterceptMessage {
          forwardInterceptMessage(id: "#{escaped_id}"#{input_str}) {
            success
          }
        }
      )
    end

    # Drop an intercept message
    def self.drop_message(message_id : String)
      escaped_id = CaidoUtils.escape_graphql_string(message_id)
      %Q(
        mutation DropInterceptMessage {
          dropInterceptMessage(id: "#{escaped_id}") {
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
      filter_clause = CaidoUtils.build_filter_clause(filter)
      
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
      escaped_name = CaidoUtils.escape_graphql_string(name)
      allowlist_str = CaidoUtils.build_string_array(allowlist)
      denylist_str = CaidoUtils.build_string_array(denylist)
      
      %Q(
        mutation CreateScope {
          createScope(input: { 
            name: "#{escaped_name}", 
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
      escaped_id = CaidoUtils.escape_graphql_string(scope_id)
      updates = [] of String
      updates << %Q(name: "#{CaidoUtils.escape_graphql_string(name.not_nil!)}") if name
      
      if allowlist
        allowlist_str = CaidoUtils.build_string_array(allowlist)
        updates << %Q(allowlist: [#{allowlist_str}])
      end
      
      if denylist
        denylist_str = CaidoUtils.build_string_array(denylist)
        updates << %Q(denylist: [#{denylist_str}])
      end
      
      %Q(
        mutation UpdateScope {
          updateScope(id: "#{escaped_id}", input: { #{updates.join(", ")} }) {
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
      escaped_id = CaidoUtils.escape_graphql_string(scope_id)
      %Q(
        mutation DeleteScope {
          deleteScope(id: "#{escaped_id}") {
            deletedId
          }
        }
      )
    end

    # Rename a scope
    def self.rename(scope_id : String, name : String)
      escaped_id = CaidoUtils.escape_graphql_string(scope_id)
      escaped_name = CaidoUtils.escape_graphql_string(name)
      %Q(
        mutation RenameScope {
          renameScope(id: "#{escaped_id}", name: "#{escaped_name}") {
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
      escaped_request_id = CaidoUtils.escape_graphql_string(request_id)
      escaped_title = CaidoUtils.escape_graphql_string(title)
      escaped_reporter = CaidoUtils.escape_graphql_string(reporter)
      desc_clause = description ? %Q(description: "#{CaidoUtils.escape_graphql_string(description)}") : ""
      
      %Q(
        mutation CreateFinding {
          createFinding(requestId: "#{escaped_request_id}", input: { 
            title: "#{escaped_title}", 
            #{desc_clause}
            reporter: "#{escaped_reporter}" 
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
      escaped_id = CaidoUtils.escape_graphql_string(finding_id)
      updates = [] of String
      updates << %Q(title: "#{CaidoUtils.escape_graphql_string(title.not_nil!)}") if title
      updates << %Q(description: "#{CaidoUtils.escape_graphql_string(description.not_nil!)}") if description
      
      %Q(
        mutation UpdateFinding {
          updateFinding(id: "#{escaped_id}", input: { #{updates.join(", ")} }) {
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
        ids_str = CaidoUtils.build_string_array(finding_ids)
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
      ids_str = CaidoUtils.build_string_array(finding_ids)
      
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
        ids_str = CaidoUtils.build_string_array(finding_ids)
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
      escaped_id = CaidoUtils.escape_graphql_string(project_id)
      %Q(
        mutation SelectProject {
          selectProject(id: "#{escaped_id}") {
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
      escaped_name = CaidoUtils.escape_graphql_string(name)
      path_clause = path ? %Q(path: "#{CaidoUtils.escape_graphql_string(path)}") : ""
      
      %Q(
        mutation CreateProject {
          createProject(input: { name: "#{escaped_name}", #{path_clause} }) {
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
      escaped_id = CaidoUtils.escape_graphql_string(project_id)
      %Q(
        mutation DeleteProject {
          deleteProject(id: "#{escaped_id}") {
            deletedId
          }
        }
      )
    end

    # Rename a project (requires cloud)
    def self.rename(project_id : String, name : String)
      escaped_id = CaidoUtils.escape_graphql_string(project_id)
      escaped_name = CaidoUtils.escape_graphql_string(name)
      %Q(
        mutation RenameProject {
          renameProject(id: "#{escaped_id}", name: "#{escaped_name}") {
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
      escaped_name = CaidoUtils.escape_graphql_string(name)
      escaped_definition = CaidoUtils.escape_graphql_string(definition)
      %Q(
        mutation CreateWorkflow {
          createWorkflow(input: { 
            name: "#{escaped_name}", 
            kind: #{kind}, 
            definition: "#{escaped_definition}" 
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
      escaped_id = CaidoUtils.escape_graphql_string(workflow_id)
      updates = [] of String
      updates << %Q(name: "#{CaidoUtils.escape_graphql_string(name.not_nil!)}") if name
      updates << %Q(definition: "#{CaidoUtils.escape_graphql_string(definition.not_nil!)}") if definition
      
      %Q(
        mutation UpdateWorkflow {
          updateWorkflow(id: "#{escaped_id}", input: { #{updates.join(", ")} }) {
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
      escaped_id = CaidoUtils.escape_graphql_string(workflow_id)
      %Q(
        mutation DeleteWorkflow {
          deleteWorkflow(id: "#{escaped_id}") {
            deletedId
          }
        }
      )
    end

    # Rename a workflow
    def self.rename(workflow_id : String, name : String)
      escaped_id = CaidoUtils.escape_graphql_string(workflow_id)
      escaped_name = CaidoUtils.escape_graphql_string(name)
      %Q(
        mutation RenameWorkflow {
          renameWorkflow(id: "#{escaped_id}", name: "#{escaped_name}") {
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
      escaped_id = CaidoUtils.escape_graphql_string(workflow_id)
      %Q(
        mutation ToggleWorkflow {
          toggleWorkflow(id: "#{escaped_id}", enabled: #{enabled}) {
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
      escaped_workflow_id = CaidoUtils.escape_graphql_string(workflow_id)
      escaped_request_id = CaidoUtils.escape_graphql_string(request_id)
      %Q(
        mutation RunActiveWorkflow {
          runActiveWorkflow(id: "#{escaped_workflow_id}", input: { requestId: "#{escaped_request_id}" }) {
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
      escaped_name = CaidoUtils.escape_graphql_string(name)
      escaped_source = CaidoUtils.escape_graphql_string(source)
      collection_clause = collection_id ? %Q(collectionId: "#{CaidoUtils.escape_graphql_string(collection_id)}") : ""
      
      %Q(
        mutation CreateReplaySession {
          createReplaySession(input: { 
            name: "#{escaped_name}", 
            source: "#{escaped_source}", 
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
      escaped_name = CaidoUtils.escape_graphql_string(name)
      %Q(
        mutation CreateReplaySessionCollection {
          createReplaySessionCollection(input: { name: "#{escaped_name}" }) {
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
      ids_str = CaidoUtils.build_string_array(session_ids)
      
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
      escaped_id = CaidoUtils.escape_graphql_string(collection_id)
      %Q(
        mutation DeleteReplaySessionCollection {
          deleteReplaySessionCollection(id: "#{escaped_id}") {
            deletedId
          }
        }
      )
    end

    # Rename a replay session
    def self.rename_session(session_id : String, name : String)
      escaped_id = CaidoUtils.escape_graphql_string(session_id)
      escaped_name = CaidoUtils.escape_graphql_string(name)
      %Q(
        mutation RenameReplaySession {
          renameReplaySession(id: "#{escaped_id}", name: "#{escaped_name}") {
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
      escaped_id = CaidoUtils.escape_graphql_string(collection_id)
      escaped_name = CaidoUtils.escape_graphql_string(name)
      %Q(
        mutation RenameReplaySessionCollection {
          renameReplaySessionCollection(id: "#{escaped_id}", name: "#{escaped_name}") {
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
      escaped_session_id = CaidoUtils.escape_graphql_string(session_id)
      escaped_collection_id = CaidoUtils.escape_graphql_string(collection_id)
      %Q(
        mutation MoveReplaySession {
          moveReplaySession(id: "#{escaped_session_id}", collectionId: "#{escaped_collection_id}") {
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
      escaped_id = CaidoUtils.escape_graphql_string(session_id)
      %Q(
        mutation StartReplayTask {
          startReplayTask(sessionId: "#{escaped_id}", input: {}) {
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
      escaped_name = CaidoUtils.escape_graphql_string(name)
      escaped_host = CaidoUtils.escape_graphql_string(host)
      %Q(
        mutation CreateAutomateSession {
          createAutomateSession(input: { 
            name: "#{escaped_name}", 
            connection: { 
              host: "#{escaped_host}", 
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
      escaped_id = CaidoUtils.escape_graphql_string(session_id)
      %Q(
        mutation DeleteAutomateSession {
          deleteAutomateSession(id: "#{escaped_id}") {
            deletedId
          }
        }
      )
    end

    # Rename an automate session
    def self.rename_session(session_id : String, name : String)
      escaped_id = CaidoUtils.escape_graphql_string(session_id)
      escaped_name = CaidoUtils.escape_graphql_string(name)
      %Q(
        mutation RenameAutomateSession {
          renameAutomateSession(id: "#{escaped_id}", name: "#{escaped_name}") {
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
      escaped_id = CaidoUtils.escape_graphql_string(session_id)
      %Q(
        mutation DuplicateAutomateSession {
          duplicateAutomateSession(id: "#{escaped_id}") {
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
      escaped_id = CaidoUtils.escape_graphql_string(session_id)
      %Q(
        mutation StartAutomateTask {
          startAutomateTask(automateSessionId: "#{escaped_id}") {
            task {
              id
            }
          }
        }
      )
    end

    # Pause an automate task
    def self.pause_task(task_id : String)
      escaped_id = CaidoUtils.escape_graphql_string(task_id)
      %Q(
        mutation PauseAutomateTask {
          pauseAutomateTask(id: "#{escaped_id}") {
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
      escaped_id = CaidoUtils.escape_graphql_string(task_id)
      %Q(
        mutation ResumeAutomateTask {
          resumeAutomateTask(id: "#{escaped_id}") {
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
      escaped_id = CaidoUtils.escape_graphql_string(task_id)
      %Q(
        mutation CancelAutomateTask {
          cancelAutomateTask(id: "#{escaped_id}") {
            success
          }
        }
      )
    end

    # Delete automate entries
    def self.delete_entries(entry_ids : Array(String))
      ids_str = CaidoUtils.build_string_array(entry_ids)
      
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
      escaped_name = CaidoUtils.escape_graphql_string(name)
      escaped_condition = CaidoUtils.escape_graphql_string(condition)
      escaped_strategy = CaidoUtils.escape_graphql_string(strategy)
      collection_clause = collection_id ? %Q(collectionId: "#{CaidoUtils.escape_graphql_string(collection_id)}") : ""
      
      %Q(
        mutation CreateTamperRule {
          createTamperRule(input: { 
            name: "#{escaped_name}", 
            condition: "#{escaped_condition}", 
            strategy: "#{escaped_strategy}", 
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
      escaped_name = CaidoUtils.escape_graphql_string(name)
      %Q(
        mutation CreateTamperRuleCollection {
          createTamperRuleCollection(input: { name: "#{escaped_name}" }) {
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
      escaped_id = CaidoUtils.escape_graphql_string(rule_id)
      updates = [] of String
      updates << %Q(name: "#{CaidoUtils.escape_graphql_string(name.not_nil!)}") if name
      updates << %Q(condition: "#{CaidoUtils.escape_graphql_string(condition.not_nil!)}") if condition
      updates << %Q(strategy: "#{CaidoUtils.escape_graphql_string(strategy.not_nil!)}") if strategy
      
      %Q(
        mutation UpdateTamperRule {
          updateTamperRule(id: "#{escaped_id}", input: { #{updates.join(", ")} }) {
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
      escaped_id = CaidoUtils.escape_graphql_string(rule_id)
      %Q(
        mutation DeleteTamperRule {
          deleteTamperRule(id: "#{escaped_id}") {
            deletedId
          }
        }
      )
    end

    # Delete a tamper rule collection
    def self.delete_collection(collection_id : String)
      escaped_id = CaidoUtils.escape_graphql_string(collection_id)
      %Q(
        mutation DeleteTamperRuleCollection {
          deleteTamperRuleCollection(id: "#{escaped_id}") {
            deletedId
          }
        }
      )
    end

    # Toggle tamper rule enabled state
    def self.toggle_rule(rule_id : String, enabled : Bool)
      escaped_id = CaidoUtils.escape_graphql_string(rule_id)
      %Q(
        mutation ToggleTamperRule {
          toggleTamperRule(id: "#{escaped_id}", enabled: #{enabled}) {
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
      escaped_id = CaidoUtils.escape_graphql_string(rule_id)
      escaped_name = CaidoUtils.escape_graphql_string(name)
      %Q(
        mutation RenameTamperRule {
          renameTamperRule(id: "#{escaped_id}", name: "#{escaped_name}") {
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
      escaped_id = CaidoUtils.escape_graphql_string(collection_id)
      escaped_name = CaidoUtils.escape_graphql_string(name)
      %Q(
        mutation RenameTamperRuleCollection {
          renameTamperRuleCollection(id: "#{escaped_id}", name: "#{escaped_name}") {
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
      escaped_rule_id = CaidoUtils.escape_graphql_string(rule_id)
      escaped_collection_id = CaidoUtils.escape_graphql_string(collection_id)
      %Q(
        mutation MoveTamperRule {
          moveTamperRule(id: "#{escaped_rule_id}", collectionId: "#{escaped_collection_id}") {
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
      escaped_name = CaidoUtils.escape_graphql_string(name)
      escaped_source = CaidoUtils.escape_graphql_string(source)
      escaped_destination = CaidoUtils.escape_graphql_string(destination)
      %Q(
        mutation CreateDNSRewrite {
          createDnsRewrite(input: { 
            name: "#{escaped_name}", 
            strategy: #{strategy}, 
            source: "#{escaped_source}", 
            destination: "#{escaped_destination}" 
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
      escaped_id = CaidoUtils.escape_graphql_string(rewrite_id)
      updates = [] of String
      updates << %Q(name: "#{CaidoUtils.escape_graphql_string(name.not_nil!)}") if name
      updates << %Q(strategy: #{strategy}) if strategy
      updates << %Q(source: "#{CaidoUtils.escape_graphql_string(source.not_nil!)}") if source
      updates << %Q(destination: "#{CaidoUtils.escape_graphql_string(destination.not_nil!)}") if destination
      
      %Q(
        mutation UpdateDNSRewrite {
          updateDnsRewrite(id: "#{escaped_id}", input: { #{updates.join(", ")} }) {
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
      escaped_id = CaidoUtils.escape_graphql_string(rewrite_id)
      %Q(
        mutation DeleteDNSRewrite {
          deleteDnsRewrite(id: "#{escaped_id}") {
            deletedId
          }
        }
      )
    end

    # Toggle DNS rewrite enabled state
    def self.toggle_rewrite(rewrite_id : String, enabled : Bool)
      escaped_id = CaidoUtils.escape_graphql_string(rewrite_id)
      %Q(
        mutation ToggleDNSRewrite {
          toggleDnsRewrite(id: "#{escaped_id}", enabled: #{enabled}) {
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
      escaped_name = CaidoUtils.escape_graphql_string(name)
      escaped_address = CaidoUtils.escape_graphql_string(address)
      %Q(
        mutation CreateDNSUpstream {
          createDnsUpstream(input: { 
            name: "#{escaped_name}", 
            kind: #{kind}, 
            address: "#{escaped_address}" 
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
      escaped_id = CaidoUtils.escape_graphql_string(upstream_id)
      updates = [] of String
      updates << %Q(name: "#{CaidoUtils.escape_graphql_string(name.not_nil!)}") if name
      updates << %Q(kind: #{kind}) if kind
      updates << %Q(address: "#{CaidoUtils.escape_graphql_string(address.not_nil!)}") if address
      
      %Q(
        mutation UpdateDNSUpstream {
          updateDnsUpstream(id: "#{escaped_id}", input: { #{updates.join(", ")} }) {
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
      escaped_id = CaidoUtils.escape_graphql_string(upstream_id)
      %Q(
        mutation DeleteDNSUpstream {
          deleteDnsUpstream(id: "#{escaped_id}") {
            deletedId
          }
        }
      )
    end
  end

  module UpstreamProxies
    # Create an HTTP upstream proxy
    def self.create_http(kind : String, address : String, allowlist : Array(String) = [] of String, denylist : Array(String) = [] of String)
      escaped_address = CaidoUtils.escape_graphql_string(address)
      allowlist_str = CaidoUtils.build_string_array(allowlist)
      denylist_str = CaidoUtils.build_string_array(denylist)
      
      %Q(
        mutation CreateUpstreamProxyHttp {
          createUpstreamProxyHttp(input: { 
            kind: #{kind}, 
            address: "#{escaped_address}", 
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
      escaped_address = CaidoUtils.escape_graphql_string(address)
      allowlist_str = CaidoUtils.build_string_array(allowlist)
      denylist_str = CaidoUtils.build_string_array(denylist)
      
      %Q(
        mutation CreateUpstreamProxySocks {
          createUpstreamProxySocks(input: { 
            kind: #{kind}, 
            address: "#{escaped_address}", 
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
      escaped_id = CaidoUtils.escape_graphql_string(proxy_id)
      %Q(
        mutation DeleteUpstreamProxyHttp {
          deleteUpstreamProxyHttp(id: "#{escaped_id}") {
            deletedId
          }
        }
      )
    end

    # Delete a SOCKS upstream proxy
    def self.delete_socks(proxy_id : String)
      escaped_id = CaidoUtils.escape_graphql_string(proxy_id)
      %Q(
        mutation DeleteUpstreamProxySocks {
          deleteUpstreamProxySocks(id: "#{escaped_id}") {
            deletedId
          }
        }
      )
    end

    # Toggle HTTP upstream proxy enabled state
    def self.toggle_http(proxy_id : String, enabled : Bool)
      escaped_id = CaidoUtils.escape_graphql_string(proxy_id)
      %Q(
        mutation ToggleUpstreamProxyHttp {
          toggleUpstreamProxyHttp(id: "#{escaped_id}", enabled: #{enabled}) {
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
      escaped_id = CaidoUtils.escape_graphql_string(proxy_id)
      %Q(
        mutation ToggleUpstreamProxySocks {
          toggleUpstreamProxySocks(id: "#{escaped_id}", enabled: #{enabled}) {
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
      escaped_model_id = CaidoUtils.escape_graphql_string(model_id)
      name_clause = name ? %Q(name: "#{CaidoUtils.escape_graphql_string(name)}") : ""
      
      %Q(
        mutation CreateAssistantSession {
          createAssistantSession(input: { modelId: "#{escaped_model_id}", #{name_clause} }) {
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
      escaped_id = CaidoUtils.escape_graphql_string(session_id)
      %Q(
        mutation DeleteAssistantSession {
          deleteAssistantSession(id: "#{escaped_id}") {
            deletedId
          }
        }
      )
    end

    # Rename an assistant session
    def self.rename_session(session_id : String, name : String)
      escaped_id = CaidoUtils.escape_graphql_string(session_id)
      escaped_name = CaidoUtils.escape_graphql_string(name)
      %Q(
        mutation RenameAssistantSession {
          renameAssistantSession(id: "#{escaped_id}", name: "#{escaped_name}") {
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
      escaped_id = CaidoUtils.escape_graphql_string(session_id)
      escaped_message = CaidoUtils.escape_graphql_string(message)
      %Q(
        mutation SendAssistantMessage {
          sendAssistantMessage(sessionId: "#{escaped_id}", message: "#{escaped_message}") {
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
      escaped_id = CaidoUtils.escape_graphql_string(task_id)
      %Q(
        mutation CancelTask {
          cancelTask(id: "#{escaped_id}") {
            success
          }
        }
      )
    end
  end
end
