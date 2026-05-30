require "./spec_helper"
require "http/server"

# Spins up a localhost GraphQL stub that replies with a caller-supplied
# (status, body) pair, then drives a real `CaidoClient` against it. Exercises
# the full transport: HTTP status checking, JSON parsing, and the
# data/errors decoding in `CaidoClient::Transport`.
private def with_graphql_server(status : Int32, body : String, & : String ->)
  server = HTTP::Server.new do |context|
    context.response.status_code = status
    context.response.print body
  end
  address = server.bind_tcp("127.0.0.1", 0)
  spawn { server.listen }
  begin
    yield "http://#{address.address}:#{address.port}/graphql"
  ensure
    server.close
  end
end

describe Caido do
  it "has a version" do
    Caido::VERSION.should eq("0.1.0")
  end
end

describe CaidoClient do
  describe "#initialize" do
    it "constructs without a token" do
      client = CaidoClient.new("http://example.invalid/graphql")
      client.should_not be_nil
    end

    it "constructs with an explicit bearer token" do
      client = CaidoClient.new("http://example.invalid/graphql", "test-token")
      client.should_not be_nil
    end

    it "constructs with custom headers hash" do
      headers = {"X-Caido-Trace" => "abc", "Authorization" => "Bearer xyz"}
      client = CaidoClient.new("http://example.invalid/graphql", headers)
      client.should_not be_nil
    end

    it "picks up CAIDO_AUTH_TOKEN from environment" do
      previous = ENV["CAIDO_AUTH_TOKEN"]?
      begin
        ENV["CAIDO_AUTH_TOKEN"] = "env-token"
        client = CaidoClient.new("http://example.invalid/graphql")
        client.should_not be_nil
      ensure
        if previous
          ENV["CAIDO_AUTH_TOKEN"] = previous
        else
          ENV.delete("CAIDO_AUTH_TOKEN")
        end
      end
    end
  end

  describe "#query" do
    it "wraps connection failures in ConnectionError" do
      # Port 1 is reserved and unreachable on all platforms — connect
      # fails immediately, which exercises the rescue branch in #query.
      client = CaidoClient.new("http://127.0.0.1:1/graphql")
      expect_raises(CaidoClient::ConnectionError, /Failed to connect/) do
        client.query("{ __typename }")
      end
    end
  end

  describe CaidoClient::GraphQLError do
    it "joins multiple error messages into the exception message" do
      err = CaidoClient::GraphQLError.new(["bad field", "unauthorized"])
      err.errors.should eq(["bad field", "unauthorized"])
      err.message.should eq("bad field; unauthorized")
    end
  end
end

describe CaidoUtils do
  describe ".escape_graphql_string" do
    it "escapes backslashes" do
      CaidoUtils.escape_graphql_string("test\\path").should eq("test\\\\path")
    end

    it "escapes double quotes" do
      CaidoUtils.escape_graphql_string(%q(test"value)).should eq(%q(test\"value))
    end

    it "escapes newlines" do
      CaidoUtils.escape_graphql_string("test\nvalue").should eq("test\\nvalue")
    end

    it "escapes carriage returns" do
      CaidoUtils.escape_graphql_string("test\rvalue").should eq("test\\rvalue")
    end

    it "escapes tabs" do
      CaidoUtils.escape_graphql_string("test\tvalue").should eq("test\\tvalue")
    end

    it "escapes backspace" do
      CaidoUtils.escape_graphql_string("test\bvalue").should eq("test\\bvalue")
    end

    it "escapes form feed" do
      CaidoUtils.escape_graphql_string("test\fvalue").should eq("test\\fvalue")
    end

    it "handles multiple special characters" do
      input = %q(test"with\nnewline)
      expected = %q(test\"with\\nnewline)
      CaidoUtils.escape_graphql_string(input).should eq(expected)
    end

    it "returns empty string unchanged" do
      CaidoUtils.escape_graphql_string("").should eq("")
    end

    it "returns normal string unchanged" do
      CaidoUtils.escape_graphql_string("normal string").should eq("normal string")
    end
  end

  describe ".build_filter_clause" do
    it "returns empty string for nil filter" do
      CaidoUtils.build_filter_clause(nil).should eq("")
    end

    it "builds filter clause with escaped value" do
      CaidoUtils.build_filter_clause("host:example.com").should eq(%Q(filter: "host:example.com"))
    end

    it "escapes special characters in filter" do
      CaidoUtils.build_filter_clause(%q(path:"test")).should eq(%Q(filter: "path:\\"test\\""))
    end
  end

  describe ".build_string_array" do
    it "returns empty string for empty array" do
      CaidoUtils.build_string_array([] of String).should eq("")
    end

    it "builds array with single item" do
      CaidoUtils.build_string_array(["item1"]).should eq(%Q("item1"))
    end

    it "builds array with multiple items" do
      CaidoUtils.build_string_array(["item1", "item2"]).should eq(%Q("item1", "item2"))
    end

    it "escapes special characters in items" do
      CaidoUtils.build_string_array([%q(test"value)]).should eq(%Q("test\\"value"))
    end
  end

  describe ".build_optional_fields" do
    it "returns empty array when all values are nil" do
      fields = [{"name", nil}, {"desc", nil}] of Tuple(String, String?)
      CaidoUtils.build_optional_fields(fields).should eq([] of String)
    end

    it "builds fields for non-nil values only" do
      fields = [{"name", "test"}, {"desc", nil}] of Tuple(String, String?)
      result = CaidoUtils.build_optional_fields(fields)
      result.size.should eq(1)
      result[0].should eq(%Q(name: "test"))
    end

    it "escapes special characters in values" do
      fields = [{"name", %q(test"value)}] of Tuple(String, String?)
      result = CaidoUtils.build_optional_fields(fields)
      result[0].should eq(%Q(name: "test\\"value"))
    end
  end

  describe ".build_pagination" do
    it "returns empty string when no pagination" do
      CaidoUtils.build_pagination.should eq("")
    end

    it "builds after clause only" do
      CaidoUtils.build_pagination(after: "cursor123").should eq(%Q(after: "cursor123"))
    end

    it "builds first clause only" do
      CaidoUtils.build_pagination(first: 50).should eq("first: 50")
    end

    it "builds both after and first clauses" do
      CaidoUtils.build_pagination(after: "cursor123", first: 50).should eq(%Q(after: "cursor123" first: 50))
    end
  end

  describe ".build_optional_string" do
    it "returns nil for nil value" do
      CaidoUtils.build_optional_string("name", nil).should be_nil
    end

    it "builds key-value string for non-nil value" do
      CaidoUtils.build_optional_string("name", "test").should eq(%Q(name: "test"))
    end

    it "escapes special characters in value" do
      CaidoUtils.build_optional_string("name", %q(test"value)).should eq(%Q(name: "test\\"value"))
    end
  end

  describe ".escape_graphql_string" do
    it "escapes unicode control characters" do
      # U+0000 (NUL)
      CaidoUtils.escape_graphql_string("\u0000").should eq("\\u0000")
    end

    it "escapes other control characters as unicode" do
      # U+0001 (SOH)
      CaidoUtils.escape_graphql_string("\u0001").should eq("\\u0001")
      # U+001F (US) - last control char before space
      CaidoUtils.escape_graphql_string("\u001f").should eq("\\u001f")
    end

    it "does not escape printable characters" do
      CaidoUtils.escape_graphql_string("Hello World! @#$%").should eq("Hello World! @#$%")
    end
  end
end

describe CaidoQueries::Requests do
  describe ".all" do
    it "generates valid query" do
      query = CaidoQueries::Requests.all
      query.should contain("query GetRequests")
      query.should contain("first: 50")
    end

    it "includes filter when provided" do
      query = CaidoQueries::Requests.all(filter: "host:example.com")
      query.should contain(%Q(filter: "host:example.com"))
    end

    it "escapes filter value" do
      query = CaidoQueries::Requests.all(filter: %q(path:"test"))
      query.should contain(%Q(filter: "path:\\"test\\""))
    end
  end

  describe ".by_id" do
    it "generates valid query" do
      query = CaidoQueries::Requests.by_id("123")
      query.should contain("query GetRequest")
      query.should contain(%Q(id: "123"))
    end

    it "escapes id value" do
      query = CaidoQueries::Requests.by_id(%q(123"456))
      query.should contain(%Q(id: "123\\"456"))
    end
  end
end

describe CaidoMutations::Scopes do
  describe ".create" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Scopes.create("Test Scope", ["*.example.com"])
      mutation.should contain("mutation CreateScope")
      mutation.should contain(%Q(name: "Test Scope"))
      mutation.should contain(%Q("*.example.com"))
    end

    it "escapes name value" do
      mutation = CaidoMutations::Scopes.create(%q(Test"Scope), ["*.example.com"])
      mutation.should contain(%Q(name: "Test\\"Scope"))
    end
  end

  describe ".rename" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Scopes.rename("scope123", "New Name")
      mutation.should contain("mutation RenameScope")
      mutation.should contain(%Q(id: "scope123"))
      mutation.should contain(%Q(name: "New Name"))
    end

    it "escapes both id and name" do
      mutation = CaidoMutations::Scopes.rename(%q(id"123), %q(name"test))
      mutation.should contain(%Q(id: "id\\"123"))
      mutation.should contain(%Q(name: "name\\"test"))
    end
  end
end

describe CaidoMutations::Findings do
  describe ".create" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Findings.create("req123", "XSS Found", "Description")
      mutation.should contain("mutation CreateFinding")
      mutation.should contain(%Q(requestId: "req123"))
      mutation.should contain(%Q(title: "XSS Found"))
    end

    it "escapes title and description" do
      mutation = CaidoMutations::Findings.create("req123", %q(XSS "vulnerability"), %q(Found in "path"))
      mutation.should contain(%Q(title: "XSS \\"vulnerability\\""))
      mutation.should contain(%Q(description: "Found in \\"path\\""))
    end
  end
end

describe CaidoMutations::Assistant do
  describe ".send_message" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Assistant.send_message("session123", "Hello")
      mutation.should contain("mutation SendAssistantMessage")
      mutation.should contain(%Q(sessionId: "session123"))
      mutation.should contain(%Q(message: "Hello"))
    end

    it "escapes message content" do
      mutation = CaidoMutations::Assistant.send_message("session123", %q(Say "hello"))
      mutation.should contain(%Q(message: "Say \\"hello\\""))
    end
  end
end

# Sitemap queries
describe CaidoQueries::Sitemap do
  describe ".root_entries" do
    it "generates valid query" do
      query = CaidoQueries::Sitemap.root_entries
      query.should contain("query GetSitemapRootEntries")
      query.should contain("sitemapRootEntries")
    end

    it "includes scope_id when provided" do
      query = CaidoQueries::Sitemap.root_entries(scope_id: "scope123")
      query.should contain(%Q(scopeId: "scope123"))
    end
  end

  describe ".descendant_entries" do
    it "generates valid query" do
      query = CaidoQueries::Sitemap.descendant_entries("parent123")
      query.should contain("query GetSitemapDescendantEntries")
      query.should contain(%Q(parentId: "parent123"))
      query.should contain("depth: DIRECT")
    end
  end

  describe ".by_id" do
    it "generates valid query" do
      query = CaidoQueries::Sitemap.by_id("entry123")
      query.should contain("query GetSitemapEntry")
      query.should contain(%Q(id: "entry123"))
    end
  end
end

# Intercept queries
describe CaidoQueries::Intercept do
  describe ".entries" do
    it "generates valid query" do
      query = CaidoQueries::Intercept.entries
      query.should contain("query GetInterceptEntries")
      query.should contain("first: 50")
    end
  end

  describe ".status" do
    it "generates valid query" do
      query = CaidoQueries::Intercept.status
      query.should contain("query GetInterceptStatus")
      query.should contain("isEnabled")
    end
  end

  describe ".options" do
    it "generates valid query" do
      query = CaidoQueries::Intercept.options
      query.should contain("query GetInterceptOptions")
      query.should contain("request")
      query.should contain("response")
    end
  end
end

# Intercept mutations
describe CaidoMutations::Intercept do
  describe ".pause" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Intercept.pause
      mutation.should contain("mutation PauseIntercept")
    end
  end

  describe ".resume" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Intercept.resume
      mutation.should contain("mutation ResumeIntercept")
    end
  end

  describe ".forward_message" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Intercept.forward_message("msg123")
      mutation.should contain("mutation ForwardInterceptMessage")
      mutation.should contain(%Q(id: "msg123"))
    end
  end

  describe ".drop_message" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Intercept.drop_message("msg123")
      mutation.should contain("mutation DropInterceptMessage")
      mutation.should contain(%Q(id: "msg123"))
    end
  end

  describe ".set_options" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Intercept.set_options(request_enabled: true)
      mutation.should contain("mutation SetInterceptOptions")
      mutation.should contain("enabled: true")
    end
  end

  describe ".delete_entries" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Intercept.delete_entries
      mutation.should contain("mutation DeleteInterceptEntries")
      mutation.should contain("deletedCount")
    end

    it "includes filter when provided" do
      mutation = CaidoMutations::Intercept.delete_entries(filter: "host:example.com")
      mutation.should contain(%Q(filter: "host:example.com"))
    end
  end
end

# Sitemap mutations
describe CaidoMutations::Sitemap do
  describe ".create_entries" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Sitemap.create_entries("req123")
      mutation.should contain("mutation CreateSitemapEntries")
      mutation.should contain(%Q(requestId: "req123"))
    end
  end

  describe ".delete_entries" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Sitemap.delete_entries(["e1", "e2"])
      mutation.should contain("mutation DeleteSitemapEntries")
      mutation.should contain(%Q("e1"))
      mutation.should contain(%Q("e2"))
    end
  end

  describe ".clear_all" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Sitemap.clear_all
      mutation.should contain("mutation ClearSitemapEntries")
    end
  end
end

# Automate queries
describe CaidoQueries::Automate do
  describe ".sessions" do
    it "generates valid query" do
      query = CaidoQueries::Automate.sessions
      query.should contain("query GetAutomateSessions")
      query.should contain("first: 50")
    end
  end

  describe ".session_by_id" do
    it "generates valid query" do
      query = CaidoQueries::Automate.session_by_id("auto123")
      query.should contain("query GetAutomateSession")
      query.should contain(%Q(id: "auto123"))
    end
  end

  describe ".tasks" do
    it "generates valid query" do
      query = CaidoQueries::Automate.tasks
      query.should contain("query GetAutomateTasks")
    end
  end
end

# Runtime query
describe CaidoQueries::Runtime do
  describe ".info" do
    it "generates valid query" do
      query = CaidoQueries::Runtime.info
      query.should contain("query GetRuntime")
      query.should contain("version")
      query.should contain("platform")
    end
  end
end

# DNS queries
describe CaidoQueries::DNS do
  describe ".rewrites" do
    it "generates valid query" do
      query = CaidoQueries::DNS.rewrites
      query.should contain("query GetDNSRewrites")
      query.should contain("strategy")
    end
  end

  describe ".upstreams" do
    it "generates valid query" do
      query = CaidoQueries::DNS.upstreams
      query.should contain("query GetDNSUpstreams")
      query.should contain("address")
    end
  end
end

# UpstreamProxies queries
describe CaidoQueries::UpstreamProxies do
  describe ".http" do
    it "generates valid query" do
      query = CaidoQueries::UpstreamProxies.http
      query.should contain("query GetUpstreamProxiesHttp")
      query.should contain("authentication")
    end
  end

  describe ".socks" do
    it "generates valid query" do
      query = CaidoQueries::UpstreamProxies.socks
      query.should contain("query GetUpstreamProxiesSocks")
      query.should contain("authentication")
    end
  end
end

# MatchReplace queries
describe CaidoQueries::MatchReplace do
  describe ".rules" do
    it "generates valid query" do
      query = CaidoQueries::MatchReplace.rules
      query.should contain("query GetMatchReplaceRules")
      query.should contain("matchReplaceRuleCollections")
    end
  end

  describe ".rule_by_id" do
    it "generates valid query" do
      query = CaidoQueries::MatchReplace.rule_by_id("rule123")
      query.should contain("query GetMatchReplaceRule")
      query.should contain(%Q(id: "rule123"))
    end
  end
end

# InstanceSettings query
describe CaidoQueries::InstanceSettings do
  describe ".get" do
    it "generates valid query" do
      query = CaidoQueries::InstanceSettings.get
      query.should contain("query GetInstanceSettings")
      query.should contain("aiProviders")
    end
  end
end

# Assistant queries
describe CaidoQueries::Assistant do
  describe ".sessions" do
    it "generates valid query" do
      query = CaidoQueries::Assistant.sessions
      query.should contain("query GetAssistantSessions")
      query.should contain("modelId")
    end
  end

  describe ".models" do
    it "generates valid query" do
      query = CaidoQueries::Assistant.models
      query.should contain("query GetAssistantModels")
      query.should contain("provider")
    end
  end
end

# Project mutations
describe CaidoMutations::Projects do
  describe ".select" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Projects.select("proj123")
      mutation.should contain("mutation SelectProject")
      mutation.should contain(%Q(id: "proj123"))
    end
  end

  describe ".create" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Projects.create("New Project")
      mutation.should contain("mutation CreateProject")
      mutation.should contain(%Q(name: "New Project"))
    end
  end

  describe ".delete" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Projects.delete("proj123")
      mutation.should contain("mutation DeleteProject")
      mutation.should contain("deletedId")
    end
  end

  describe ".rename" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Projects.rename("proj123", "Renamed")
      mutation.should contain("mutation RenameProject")
      mutation.should contain(%Q(name: "Renamed"))
    end
  end
end

# Workflow mutations
describe CaidoMutations::Workflows do
  describe ".create" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Workflows.create("My Workflow", "ACTIVE", "{}")
      mutation.should contain("mutation CreateWorkflow")
      mutation.should contain(%Q(name: "My Workflow"))
      mutation.should contain("kind: ACTIVE")
    end
  end

  describe ".update" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Workflows.update("wf123", name: "Updated")
      mutation.should contain("mutation UpdateWorkflow")
      mutation.should contain(%Q(name: "Updated"))
    end
  end

  describe ".delete" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Workflows.delete("wf123")
      mutation.should contain("mutation DeleteWorkflow")
      mutation.should contain("deletedId")
    end
  end

  describe ".toggle" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Workflows.toggle("wf123", true)
      mutation.should contain("mutation ToggleWorkflow")
      mutation.should contain("enabled: true")
    end
  end

  describe ".run_active" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Workflows.run_active("wf123", "req456")
      mutation.should contain("mutation RunActiveWorkflow")
      mutation.should contain(%Q(requestId: "req456"))
    end
  end
end

# Request mutations
describe CaidoMutations::Requests do
  describe ".update_metadata" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Requests.update_metadata("req123", color: "red")
      mutation.should contain("mutation UpdateRequestMetadata")
      mutation.should contain(%Q(id: "req123"))
      mutation.should contain(%Q(color: "red"))
    end
  end

  describe ".render" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Requests.render("req123")
      mutation.should contain("mutation RenderRequest")
      mutation.should contain(%Q(id: "req123"))
    end
  end
end

# New modules: FilterPresets
describe CaidoQueries::FilterPresets do
  describe ".all" do
    it "generates valid query" do
      query = CaidoQueries::FilterPresets.all
      query.should contain("query GetFilterPresets")
      query.should contain("filterPresets")
      query.should contain("alias")
      query.should contain("clause")
    end
  end

  describe ".by_id" do
    it "generates valid query" do
      query = CaidoQueries::FilterPresets.by_id("filter123")
      query.should contain("query GetFilterPreset")
      query.should contain(%Q(id: "filter123"))
    end
  end
end

describe CaidoMutations::FilterPresets do
  describe ".create" do
    it "generates valid mutation" do
      mutation = CaidoMutations::FilterPresets.create("My Filter", "host:example.com")
      mutation.should contain("mutation CreateFilterPreset")
      mutation.should contain(%Q(name: "My Filter"))
      mutation.should contain(%Q(clause: "host:example.com"))
    end

    it "includes alias when provided" do
      mutation = CaidoMutations::FilterPresets.create("My Filter", "host:example.com", filter_alias: "mf")
      mutation.should contain(%Q(alias: "mf"))
    end
  end

  describe ".update" do
    it "generates valid mutation" do
      mutation = CaidoMutations::FilterPresets.update("filter123", name: "Updated Filter")
      mutation.should contain("mutation UpdateFilterPreset")
      mutation.should contain(%Q(id: "filter123"))
      mutation.should contain(%Q(name: "Updated Filter"))
    end
  end

  describe ".delete" do
    it "generates valid mutation" do
      mutation = CaidoMutations::FilterPresets.delete("filter123")
      mutation.should contain("mutation DeleteFilterPreset")
      mutation.should contain(%Q(id: "filter123"))
      mutation.should contain("deletedId")
    end
  end
end

# New modules: HostedFiles
describe CaidoQueries::HostedFiles do
  describe ".all" do
    it "generates valid query" do
      query = CaidoQueries::HostedFiles.all
      query.should contain("query GetHostedFiles")
      query.should contain("hostedFiles")
      query.should contain("size")
      query.should contain("status")
    end
  end
end

describe CaidoMutations::HostedFiles do
  describe ".upload" do
    it "generates valid mutation" do
      mutation = CaidoMutations::HostedFiles.upload("test.txt", "/tmp/test.txt")
      mutation.should contain("mutation UploadHostedFile")
      mutation.should contain(%Q(name: "test.txt"))
      mutation.should contain(%Q(path: "/tmp/test.txt"))
    end
  end

  describe ".rename" do
    it "generates valid mutation" do
      mutation = CaidoMutations::HostedFiles.rename("file123", "new_name.txt")
      mutation.should contain("mutation RenameHostedFile")
      mutation.should contain(%Q(id: "file123"))
      mutation.should contain(%Q(name: "new_name.txt"))
    end
  end

  describe ".delete" do
    it "generates valid mutation" do
      mutation = CaidoMutations::HostedFiles.delete("file123")
      mutation.should contain("mutation DeleteHostedFile")
      mutation.should contain(%Q(id: "file123"))
      mutation.should contain("deletedId")
    end
  end
end

# New modules: Environment mutations
describe CaidoQueries::Environments do
  describe ".by_id" do
    it "generates valid query" do
      query = CaidoQueries::Environments.by_id("env123")
      query.should contain("query GetEnvironment")
      query.should contain(%Q(id: "env123"))
      query.should contain("variables")
      query.should contain("version")
    end
  end
end

describe CaidoMutations::Environments do
  describe ".create" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Environments.create("Production")
      mutation.should contain("mutation CreateEnvironment")
      mutation.should contain(%Q(name: "Production"))
    end
  end

  describe ".delete" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Environments.delete("env123")
      mutation.should contain("mutation DeleteEnvironment")
      mutation.should contain(%Q(id: "env123"))
      mutation.should contain("deletedId")
    end
  end

  describe ".select" do
    it "generates valid mutation with id" do
      mutation = CaidoMutations::Environments.select("env123")
      mutation.should contain("mutation SelectEnvironment")
      mutation.should contain(%Q(id: "env123"))
    end

    it "generates valid mutation without id" do
      mutation = CaidoMutations::Environments.select
      mutation.should contain("mutation SelectEnvironment")
      mutation.should contain("selectEnvironment")
    end
  end
end

# New: Plugin install mutation
describe CaidoMutations::Plugins do
  describe ".install" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Plugins.install("my-plugin")
      mutation.should contain("mutation InstallPluginPackage")
      mutation.should contain(%Q(manifestId: "my-plugin"))
    end
  end
end

# New: Tasks query
describe CaidoQueries::Tasks do
  describe ".all" do
    it "generates valid query" do
      query = CaidoQueries::Tasks.all
      query.should contain("query GetTasks")
      query.should contain("tasks")
      query.should contain("__typename")
      query.should contain("ReplayTask")
    end
  end
end

# New: Response query
describe CaidoQueries::Responses do
  describe ".by_id" do
    it "generates valid query" do
      query = CaidoQueries::Responses.by_id("resp123")
      query.should contain("query GetResponse")
      query.should contain(%Q(id: "resp123"))
      query.should contain("statusCode")
      query.should contain("raw")
    end
  end
end

# New: Replay entry and session entries
describe CaidoQueries::Replay do
  describe ".entry_by_id" do
    it "generates valid query" do
      query = CaidoQueries::Replay.entry_by_id("entry123")
      query.should contain("query GetReplayEntry")
      query.should contain(%Q(id: "entry123"))
      query.should contain("connection")
      query.should contain("session")
    end
  end

  describe ".session_entries" do
    it "generates valid query" do
      query = CaidoQueries::Replay.session_entries("session123")
      query.should contain("query GetReplaySessionEntries")
      query.should contain(%Q(id: "session123"))
      query.should contain("entries")
    end
  end
end

# New: Replay set_active_entry mutation
describe CaidoMutations::Replay do
  describe ".set_active_entry" do
    it "generates valid mutation" do
      mutation = CaidoMutations::Replay.set_active_entry("session123", "entry456")
      mutation.should contain("mutation SetActiveReplaySessionEntry")
      mutation.should contain(%Q(id: "session123"))
      mutation.should contain(%Q(entryId: "entry456"))
    end
  end
end

# Updated fields tests
describe CaidoQueries::Scopes do
  describe ".all" do
    it "includes indexed field" do
      query = CaidoQueries::Scopes.all
      query.should contain("indexed")
    end
  end
end

describe CaidoQueries::Findings do
  describe ".by_id" do
    it "includes host, path, hidden fields" do
      query = CaidoQueries::Findings.by_id("finding123")
      query.should contain("host")
      query.should contain("path")
      query.should contain("hidden")
    end
  end
end

describe CaidoQueries::Projects do
  describe ".all" do
    it "includes new fields from JS SDK" do
      query = CaidoQueries::Projects.all
      query.should contain("temporary")
      query.should contain("readOnly")
      query.should contain("updatedAt")
    end
  end
end

describe CaidoQueries::Workflows do
  describe ".all" do
    it "includes new fields from JS SDK" do
      query = CaidoQueries::Workflows.all
      query.should contain("readOnly")
      query.should contain("createdAt")
      query.should contain("updatedAt")
    end
  end
end

describe CaidoQueries::Viewer do
  describe ".info" do
    it "includes union types" do
      query = CaidoQueries::Viewer.info
      query.should contain("CloudUser")
      query.should contain("GuestUser")
      query.should contain("ScriptUser")
      query.should contain("__typename")
    end
  end
end

describe "CaidoUtils GraphQL injection guards" do
  describe ".safe_enum_value" do
    it "accepts plain enum values" do
      CaidoUtils.safe_enum_value("ASC").should eq("ASC")
      CaidoUtils.safe_enum_value("UPPER_SNAKE_1").should eq("UPPER_SNAKE_1")
    end

    it "rejects values that try to break out of the enum slot" do
      expect_raises(ArgumentError) { CaidoUtils.safe_enum_value("ASC } viewer { id }") }
      expect_raises(ArgumentError) { CaidoUtils.safe_enum_value(%q(ASC", extra: "x)) }
      expect_raises(ArgumentError) { CaidoUtils.safe_enum_value("ASC EXTRA") }
      expect_raises(ArgumentError) { CaidoUtils.safe_enum_value("") }
    end
  end

  describe ".to_graphql_value" do
    it "serializes scalars and nested objects" do
      CaidoUtils.to_graphql_value(nil).should eq("null")
      CaidoUtils.to_graphql_value(true).should eq("true")
      CaidoUtils.to_graphql_value(42).should eq("42")
      CaidoUtils.to_graphql_value({"a" => {"b" => "c"}}).should eq(%q({ a: { b: "c" } }))
      CaidoUtils.to_graphql_value(["a", "b"]).should eq(%q(["a", "b"]))
    end

    it "rejects keys that would inject GraphQL" do
      expect_raises(ArgumentError) { CaidoUtils.to_graphql_value({"a } b" => 1}) }
    end

    it "escapes attempts to break out of string values" do
      payload = {"k" => %q(v" }, attack: "x)}
      result = CaidoUtils.to_graphql_value(payload)
      # Embedded quotes must be backslash-escaped so the GraphQL string
      # literal stays balanced.
      result.should eq(%q({ k: "v\" }, attack: \"x" }))
    end
  end

  describe "callers that interpolate enum-style args" do
    it "raises on injection in workflow kind" do
      expect_raises(ArgumentError) do
        CaidoMutations::Workflows.create("n", "PASSIVE } extra { x ", "{}")
      end
    end

    it "raises on injection in DNS rewrite strategy" do
      expect_raises(ArgumentError) do
        CaidoMutations::DNS.create_rewrite("n", "BLOCK } extra ", "s", "d")
      end
    end

    it "raises on injection in request order" do
      expect_raises(ArgumentError) do
        CaidoQueries::Requests.all(order: "ASC } viewer { id }")
      end
    end
  end

  describe "InstanceSettings.set hash overload" do
    it "serializes a hash into a safe GraphQL object literal" do
      query = CaidoMutations::InstanceSettings.set({
        "aiProviders" => {"openai" => {"apiKey" => "secret"}},
      })
      query.should contain(%q(aiProviders: { openai: { apiKey: "secret" } }))
    end

    it "escapes attempts to break out of string values" do
      query = CaidoMutations::InstanceSettings.set({
        "aiProviders" => {"openai" => {"apiKey" => %q(a" }, attack: "x)}},
      })
      # Quote and brace are escaped, so the embedded payload stays inside
      # the apiKey string literal instead of injecting sibling fields.
      query.should contain(%q(apiKey: "a\" }, attack: \"x"))
    end
  end
end

describe "CaidoClient#query error handling (transport)" do
  it "returns the decoded {data, errors, loading} tuple on success" do
    body = %({"data":{"viewer":{"id":"42"}}})
    with_graphql_server(200, body) do |endpoint|
      client = CaidoClient.new(endpoint)
      data, errors, _loading = client.query("{ viewer { id } }")
      errors.should be_nil
      data.should_not be_nil
      data.as(JSON::Any)["viewer"]["id"].as_s.should eq("42")
    end
  end

  it "raises GraphQLError on an errors-only response (plural key, no data)" do
    # GraphQL puts failures under the PLURAL `errors` key and may omit
    # `data` entirely. The old code read `error` (singular) and bracket-
    # indexed `data`, so this body used to be silently swallowed AND crash
    # with KeyError. It must now surface as a GraphQLError.
    body = %({"errors":[{"message":"Field 'bogus' doesn't exist"}]})
    with_graphql_server(200, body) do |endpoint|
      client = CaidoClient.new(endpoint)
      expect_raises(CaidoClient::GraphQLError, /Field 'bogus' doesn't exist/) do
        client.query("{ bogus }")
      end
    end
  end

  it "raises GraphQLError on a partial data + errors response" do
    # A partial response carries both `data` and `errors`. The errors must
    # win — a half-populated result is still a failure the caller must see.
    body = %({"data":{"viewer":null},"errors":[{"message":"unauthorized"}]})
    with_graphql_server(200, body) do |endpoint|
      client = CaidoClient.new(endpoint)
      begin
        client.query("{ viewer { id } }")
        fail "should have raised GraphQLError"
      rescue ex : CaidoClient::GraphQLError
        ex.errors.should eq(["unauthorized"])
      end
    end
  end

  it "raises ConnectionError (not JSON::ParseException) on a 500 + HTML body" do
    # A 401/403/500 typically returns an HTML or empty body. The old code
    # fed that straight into JSON.parse, raising a bare JSON::ParseException
    # indistinguishable from a real malformed-JSON bug. It must now be a
    # ConnectionError carrying the HTTP status.
    body = "<html><body>500 Internal Server Error</body></html>"
    with_graphql_server(500, body) do |endpoint|
      client = CaidoClient.new(endpoint)
      expect_raises(CaidoClient::ConnectionError, /500/) do
        client.query("{ viewer { id } }")
      end
    end
  end

  it "raises ConnectionError on a 200 with a non-JSON body" do
    # Even a 200 can carry junk (a misconfigured proxy, an auth redirect
    # page). That should be a ConnectionError, never a raw parse exception.
    with_graphql_server(200, "not json at all") do |endpoint|
      client = CaidoClient.new(endpoint)
      expect_raises(CaidoClient::ConnectionError) do
        client.query("{ viewer { id } }")
      end
    end
  end
end
