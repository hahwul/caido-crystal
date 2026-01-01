# Utility functions for Caido Crystal client

module CaidoUtils
  # Escapes a string for safe use in GraphQL queries
  # Prevents GraphQL injection attacks by escaping special characters
  def self.escape_graphql_string(value : String) : String
    value.gsub("\\", "\\\\")
         .gsub("\"", "\\\"")
         .gsub("\n", "\\n")
         .gsub("\r", "\\r")
         .gsub("\t", "\\t")
         .gsub("\b", "\\b")
         .gsub("\f", "\\f")
  end

  # Helper to build pagination clauses
  def self.build_pagination(after : String? = nil, first : Int32? = nil) : String
    clauses = [] of String
    clauses << %Q(after: "#{escape_graphql_string(after.not_nil!)}") if after
    clauses << "first: #{first}" if first
    clauses.join(" ")
  end

  # Helper to build filter clause
  def self.build_filter_clause(filter : String?) : String
    filter ? %Q(filter: "#{escape_graphql_string(filter)}") : ""
  end

  # Helper to build an array of strings for GraphQL
  def self.build_string_array(items : Array(String)) : String
    items.map { |item| %Q("#{escape_graphql_string(item)}") }.join(", ")
  end

  # Helper to build optional string argument
  def self.build_optional_string(key : String, value : String?) : String?
    value ? %Q(#{key}: "#{escape_graphql_string(value)}") : nil
  end
end
