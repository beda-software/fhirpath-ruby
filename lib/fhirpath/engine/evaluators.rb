# frozen_string_literal: true

require_relative "evaluators/expressions"
require_relative "evaluators/member_invocation"
require_relative "evaluators/literals"

module Fhirpath
  module Engine
    # Ruby port of fhirpath-py's fhirpathpy/engine/evaluators/__init__.py: dispatch table from
    # AST node "type" to the function that evaluates it, plus the term/identifier/invocation
    # evaluators. Unary/binary *Expression evaluators live in evaluators/expressions.rb, literal
    # evaluators live in evaluators/literals.rb; this file is reopened by both.
    module Evaluators
      class << self
        def identifier(_ctx, _parent_data, node)
          [node["text"].sub(/\A"/, "").sub(/"\z/, "")]
        end

        def this_invocation(ctx, _parent_data, _node)
          Util.arraify(ctx[:this])
        end

        def index_invocation(ctx, _parent_data, _node)
          Util.arraify(ctx[:index])
        end

        def total_invocation(ctx, _parent_data, _node)
          Util.arraify(ctx[:total])
        end

        # Ports fhirpath-py's external_constant_term ("%name"/"%`escaped name`" environment
        # variables, https://hl7.org/fhirpath/#environment-variables).
        def external_constant_term(ctx, _parent_data, node)
          var_name = node["children"][0]["children"][0]["text"].delete("`")
          unless ctx[:vars].key?(var_name)
            raise Fhirpath::Error, "Attempting to access an undefined environment variable: #{var_name}"
          end

          Util.arraify(ctx[:vars][var_name])
        end

        def literal_term(ctx, parent_data, node)
          term = node["children"]&.first
          term ? Engine.do_eval(ctx, parent_data, term) : [node["text"]]
        end

        def parenthesized_term(ctx, parent_data, node)
          Engine.do_eval(ctx, parent_data, node["children"][0])
        end

        def invocation_term(ctx, parent_data, node)
          Engine.do_eval(ctx, parent_data, node["children"][0])
        end

        def term_expression(ctx, parent_data, node)
          Engine.do_eval(ctx, parent_data, node["children"][0])
        end

        def invocation_expression(ctx, parent_data, node)
          node["children"].reduce(parent_data) { |acc, child| Engine.do_eval(ctx, acc, child) }
        end

        def indexer_expression(ctx, parent_data, node)
          coll = Engine.do_eval(ctx, parent_data, node["children"][0])
          idx = Engine.do_eval(ctx, parent_data, node["children"][1])
          return [] if Util.empty?(idx)

          idx_num = idx[0].to_i
          coll && idx_num >= 0 && coll.length > idx_num ? [coll[idx_num]] : []
        end

        def functn(ctx, parent_data, node)
          node["children"].map { |child| Engine.do_eval(ctx, parent_data, child) }
        end

        def param_list(_ctx, _parent_data, node)
          node
        end

        def function_invocation(ctx, parent_data, node)
          args = Engine.do_eval(ctx, parent_data, node["children"][0])
          fn_name = args[0]
          args = args[1..] || []

          raw_params = nil
          raw_params = args[0]["children"] if args[0].is_a?(::Hash) && args[0].key?("children")

          Engine.do_invoke(ctx, fn_name, parent_data, raw_params)
        end
      end

      DISPATCH = {
        "Functn" => method(:functn),
        "ParamList" => method(:param_list),
        "Identifier" => method(:identifier),
        "LiteralTerm" => method(:literal_term),
        "NullLiteral" => method(:null_literal),
        "NumberLiteral" => method(:number_literal),
        "StringLiteral" => method(:string_literal),
        "BooleanLiteral" => method(:boolean_literal),
        "QuantityLiteral" => method(:quantity_literal),
        "DateTimeLiteral" => method(:date_time_literal),
        "TimeLiteral" => method(:time_literal),
        "InvocationTerm" => method(:invocation_term),
        "ParenthesizedTerm" => method(:parenthesized_term),
        "ThisInvocation" => method(:this_invocation),
        "IndexInvocation" => method(:index_invocation),
        "TotalInvocation" => method(:total_invocation),
        "ExternalConstantTerm" => method(:external_constant_term),
        "MemberInvocation" => method(:member_invocation),
        "FunctionInvocation" => method(:function_invocation),
        "PolarityExpression" => method(:polarity_expression),
        "IndexerExpression" => method(:indexer_expression),
        "TermExpression" => method(:term_expression),
        "InvocationExpression" => method(:invocation_expression),
        "UnionExpression" => method(:union_expression),
        "EqualityExpression" => method(:op_expression),
        "InequalityExpression" => method(:op_expression),
        "TypeExpression" => method(:type_expression),
        "MembershipExpression" => method(:membership_expression),
        "OrExpression" => method(:op_expression),
        "ImpliesExpression" => method(:op_expression),
        "AndExpression" => method(:op_expression),
        "XorExpression" => method(:op_expression),
        "AdditiveExpression" => method(:op_expression),
        "MultiplicativeExpression" => method(:op_expression)
      }.freeze
    end
  end
end
