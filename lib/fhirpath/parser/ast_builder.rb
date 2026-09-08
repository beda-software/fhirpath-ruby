# frozen_string_literal: true

module Fhirpath
  module Parser
    # Walks the native ANTLR4 parse tree (see Fhirpath::Parser.parse) and builds the same
    # generic AST shape as fhirpath-py's ASTPathListener: each node is a Hash with "type",
    # optional "text", "terminalNodeText" (direct terminal children's text), and optional
    # "children" (present only when there's at least one non-terminal child).
    module AstBuilder
      # Port of ASTPathListener.py's has_node_type_text: which node types carry source text.
      TEXT_NODE_TYPES = %w[
        LiteralTerm
        Identifier
        TypeSpecifier
        InvocationExpression
        TermExpression
      ].freeze

      class << self
        def build(ctx)
          type = node_type(ctx)
          node = { "type" => type, "terminalNodeText" => terminal_text(ctx) }
          node["text"] = ctx.text if text_node?(type)

          children = rule_children(ctx).map { |child| build(child) }
          node["children"] = children unless children.empty?

          node
        end

        private

        def terminal_text(ctx)
          ctx.children.select { |child| child.is_a?(::FHIRPathParser::TerminalNodeImpl) }.map(&:text)
        end

        def rule_children(ctx)
          ctx.children.reject { |child| child.is_a?(::FHIRPathParser::TerminalNodeImpl) }
        end

        def node_type(ctx)
          ctx.type_name.split("::").last.delete_suffix("Context")
        end

        def text_node?(type)
          type.end_with?("Literal") || TEXT_NODE_TYPES.include?(type)
        end
      end
    end
  end
end
