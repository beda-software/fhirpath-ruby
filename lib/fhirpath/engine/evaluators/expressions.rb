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
      end
    end
  end
end
