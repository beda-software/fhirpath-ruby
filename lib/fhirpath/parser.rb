# frozen_string_literal: true

require "fhir_path_parser"
require_relative "parser/ast_builder"

module Fhirpath
  # Ruby port of fhirpath-py's fhirpathpy/parser package. Parses a FHIRPath expression string
  # into the same generic AST shape fhirpath-py produces (see AstBuilder), using a native
  # ANTLR4 parser generated from FHIRPath.g4 via the antlr4-native gem — run
  # `rake parser:setup compile` once before requiring this file (see rakelib/parser.rake).
  module Parser
    def self.parse(expression)
      parser = FHIRPathParser::Parser.parse(expression)
      root = parser.expression

      raise Fhirpath::Error, "Failed to parse #{expression.inspect}" if parser.syntax_error_count.positive?

      { "children" => [AstBuilder.build(root)] }
    end
  end
end
