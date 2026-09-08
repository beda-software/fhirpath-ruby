# frozen_string_literal: true

require "bigdecimal"

require_relative "evaluators/expressions"
require_relative "evaluators/member_invocation"

module Fhirpath
  module Engine
    # Ruby port of fhirpath-py's fhirpathpy/engine/evaluators/__init__.py: dispatch table from
    # AST node "type" to the function that evaluates it, plus the term/identifier/invocation
    # evaluators. Unary/binary *Expression evaluators live in evaluators/expressions.rb; this
    # file is reopened by both.
    module Evaluators
      class << self
        def identifier(_ctx, _parent_data, node)
          [node["text"].sub(/\A"/, "").sub(/"\z/, "")]
        end

        def number_literal(_ctx, _parent_data, node)
          value = BigDecimal(node["text"])
          int_value = value.to_i
          [value == int_value ? int_value : value]
        end

        def string_literal(_ctx, _parent_data, node)
          text = node["text"].sub(/\A['"]/, "").sub(/['"]\z/, "")
          text = text.gsub("\\'", "'")
                     .gsub("\\`", "`")
                     .gsub('\\"', '"')
                     .gsub("\\r", "\r")
                     .gsub("\\n", "\n")
                     .gsub("\\t", "\t")
                     .gsub("\\f", "\f")
                     .gsub("\\\\", "\\")
          [text.gsub(/\\u(\h{4})/) { [::Regexp.last_match(1).to_i(16)].pack("U") }]
        end

        def literal_term(ctx, parent_data, node)
          term = node["children"]&.first
          term ? Engine.do_eval(ctx, parent_data, term) : [node["text"]]
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
        "NumberLiteral" => method(:number_literal),
        "StringLiteral" => method(:string_literal),
        "InvocationTerm" => method(:invocation_term),
        "MemberInvocation" => method(:member_invocation),
        "FunctionInvocation" => method(:function_invocation),
        "PolarityExpression" => method(:polarity_expression),
        "IndexerExpression" => method(:indexer_expression),
        "TermExpression" => method(:term_expression),
        "InvocationExpression" => method(:invocation_expression),
        "EqualityExpression" => method(:op_expression)
      }.freeze
    end
  end
end
