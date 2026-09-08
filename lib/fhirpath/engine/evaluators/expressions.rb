# frozen_string_literal: true

module Fhirpath
  module Engine
    # Unary/prefix and infix-operator expression evaluators; see evaluators.rb for
    # member/index/function invocation, chaining, and the node-type dispatch table.
    module Evaluators
      class << self
        def polarity_expression(ctx, parent_data, node)
          sign = node["terminalNodeText"].first
          result = Engine.do_eval(ctx, parent_data, node["children"][0])
          raise Fhirpath::Error, "Unary #{sign} can only be applied to an individual number." if result.length != 1

          value = Util.get_data(result.first)
          raise Fhirpath::Error, "Unary #{sign} can only be applied to a number." unless value.is_a?(::Numeric)

          [sign == "-" ? -value : value]
        end

        # Ports fhirpath-py's op_expression: reads the infix operator's symbol off the node and
        # dispatches to the matching invocation (e.g. EqualityExpression's "=").
        def op_expression(ctx, parent_data, node)
          op = node["terminalNodeText"].first
          Engine.infix_invoke(ctx, op, parent_data, node["children"])
        end

        # Unlike op_expression, "|" is fixed rather than read off the node.
        def union_expression(ctx, parent_data, node)
          Engine.infix_invoke(ctx, "|", parent_data, node["children"])
        end

        # Ports fhirpath-py's alias_op_expression({"is": "isOp", "as": "asOp"}): "is"/"as" used
        # as infix operators (e.g. "x is Boolean") dispatch to the "...Op" invocation names.
        TYPE_EXPRESSION_ALIASES = { "is" => "isOp", "as" => "asOp" }.freeze

        def type_expression(ctx, parent_data, node)
          aliased_op_expression(ctx, parent_data, node, TYPE_EXPRESSION_ALIASES)
        end

        # Ports fhirpath-py's alias_op_expression({"contains": "containsOp", "in": "inOp"}).
        MEMBERSHIP_EXPRESSION_ALIASES = { "contains" => "containsOp", "in" => "inOp" }.freeze

        def membership_expression(ctx, parent_data, node)
          aliased_op_expression(ctx, parent_data, node, MEMBERSHIP_EXPRESSION_ALIASES)
        end

        private

        def aliased_op_expression(ctx, parent_data, node, aliases)
          op = node["terminalNodeText"].first
          alias_name = aliases[op]
          raise Fhirpath::Error, "Do not know how to alias #{op} by #{aliases}" unless alias_name

          Engine.infix_invoke(ctx, alias_name, parent_data, node["children"])
        end
      end
    end
  end
end
