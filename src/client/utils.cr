# Utility functions for Caido client

require "json"

module CaidoUtils
  # GraphQL enum / name pattern: starts with letter or underscore, then
  # letters, digits, or underscores. We accept the broader Name production
  # so callers can pass either UPPER_SNAKE enums or directives/identifiers.
  GRAPHQL_NAME_PATTERN = /\A[_A-Za-z][_0-9A-Za-z]*\z/

  # Validates a GraphQL enum / name value before it is interpolated unquoted
  # into a query body. Rejects any input containing characters that could
  # break out of the enum slot and inject arbitrary GraphQL.
  #
  # Raises ArgumentError on invalid input. This is intentionally strict: a
  # GraphQL enum value is a Name and must not contain spaces, braces, commas,
  # quotes, or any control characters.
  def self.safe_enum_value(value : String) : String
    unless GRAPHQL_NAME_PATTERN.matches?(value)
      raise ArgumentError.new("Invalid GraphQL enum value: #{value.inspect}")
    end
    value
  end

  # Serializes a Crystal value (Hash, Array, scalar) into a GraphQL value
  # literal using the GraphQL grammar (object keys are unquoted Names; string
  # values are quoted and escaped). Use this to build mutation `input:`
  # arguments from structured data instead of splicing a raw string.
  def self.to_graphql_value(value) : String
    case value
    when Nil
      "null"
    when Bool
      value ? "true" : "false"
    when Int, Float
      value.to_s
    when String
      %Q("#{escape_graphql_string(value)}")
    when Symbol
      safe_enum_value(value.to_s)
    when Hash
      pairs = value.map do |k, v|
        key = safe_enum_value(k.to_s)
        "#{key}: #{to_graphql_value(v)}"
      end
      "{ #{pairs.join(", ")} }"
    when Array, Tuple
      "[#{value.map { |v| to_graphql_value(v) }.join(", ")}]"
    when JSON::Any
      to_graphql_value(value.raw)
    else
      raise ArgumentError.new("Cannot serialize #{value.class} to GraphQL value")
    end
  end

  # Escapes a string for safe use in GraphQL queries
  # Prevents GraphQL injection attacks by escaping special characters
  def self.escape_graphql_string(value : String) : String
    String.build(value.bytesize) do |io|
      value.each_char do |char|
        case char
        when '\\' then io << "\\\\"
        when '"'  then io << "\\\""
        when '\n' then io << "\\n"
        when '\r' then io << "\\r"
        when '\t' then io << "\\t"
        when '\b' then io << "\\b"
        when '\f' then io << "\\f"
        else
          if char.ord < 0x20
            io << "\\u"
            io << char.ord.to_s(16).rjust(4, '0')
          else
            io << char
          end
        end
      end
    end
  end

  # Helper to build pagination clauses
  def self.build_pagination(after : String? = nil, first : Int32? = nil, before : String? = nil, last : Int32? = nil) : String
    clauses = [] of String
    clauses << %Q(after: "#{escape_graphql_string(after)}") if after
    clauses << "first: #{first}" if first
    clauses << %Q(before: "#{escape_graphql_string(before)}") if before
    clauses << "last: #{last}" if last
    clauses.join(" ")
  end

  # Helper to build optional update fields for mutations
  def self.build_optional_fields(fields : Array(Tuple(String, String?))) : Array(String)
    parts = [] of String
    fields.each do |key, value|
      parts << %Q(#{key}: "#{escape_graphql_string(value)}") if value
    end
    parts
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

  # Wraps an argument list in parentheses, or returns an empty string when
  # every clause is blank.
  #
  # GraphQL's `Arguments` production requires at least one argument, so a
  # field with no arguments must be written *without* parentheses — emitting
  # `field()` is a syntax error the server rejects before it ever looks at
  # the schema.
  def self.build_arguments(*clauses : String?) : String
    parts = clauses.to_a.compact.reject(&.blank?)
    parts.empty? ? "" : "(#{parts.join(", ")})"
  end
end
