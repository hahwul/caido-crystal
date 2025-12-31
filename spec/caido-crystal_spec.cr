require "./spec_helper"

describe Caido::Crystal do
  it "has a version" do
    Caido::Crystal::VERSION.should eq("0.1.0")
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
      CaidoUtils.build_filter_clause(%q(path:"test")).should eq(%Q(filter: "path:\\\"test\\\""))
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
      query.should contain(%Q(filter: "path:\\\"test\\\""))
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
