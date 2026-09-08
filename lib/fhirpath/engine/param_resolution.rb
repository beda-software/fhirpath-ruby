# frozen_string_literal: true

module Fhirpath
  # Resolves a raw AST param node into the value/lambda an invocation function expects, given
  # its declared param type ("Expr", "Any", "AnyAtRoot", "TypeSpecifier", "Integer", "String").
  # Ported from fhirpath-py's fhirpathpy/engine/__init__.py make_param + type_specifier. Split
  # out of engine.rb to keep that file's module body short; reopens the same Engine module.
  module Engine
    class << self
      SINGLETON_PARAM_CHECKS = {
        "Integer" => ->(data) { data.is_a?(::Numeric) && data.to_i == data },
        "Number" => ->(data) { data.is_a?(::Numeric) },
        "String" => ->(data) { data.is_a?(::String) },
        "Boolean" => ->(data) { [true, false].include?(data) }
      }.freeze

      def make_param(ctx, parent_data, node_type, param)
        return build_expr_param(ctx, param) if node_type == "Expr"
        return eval_param(ctx, parent_data, param) if node_type == "Any"
        return eval_param(ctx, ctx[:this] || ctx[:root], param) if node_type == "AnyAtRoot"
        return type_specifier(param) if node_type == "TypeSpecifier"
        return check_singleton_param(ctx, parent_data, param, node_type) if SINGLETON_PARAM_CHECKS.key?(node_type)

        raise Fhirpath::Error, "Implement me for #{node_type}"
      end

      private

      # Ports fhirpath-py's make_param's singleton + param_check_table handling: evaluate the
      # param as a singleton against parent_data, then require it to satisfy the given type.
      def check_singleton_param(ctx, parent_data, param, type_name)
        ctx[:this] = parent_data
        res = do_eval(ctx, parent_data, param)
        return [] if res.empty?

        raise Fhirpath::Error, "Unexpected collection; expected singleton of type #{type_name}" if res.length > 1

        data = Util.get_data(res.first)
        unless SINGLETON_PARAM_CHECKS[type_name].call(data)
          raise Fhirpath::Error, "Expected #{type_name.downcase}, got: #{data.inspect}"
        end

        data
      end

      # Ports fhirpath-py's module-level type_specifier: regardless of how the parameter node
      # is shaped internally, its source text (e.g. "string", "FHIR.Patient") is what matters.
      def type_specifier(node)
        identifiers = node["text"].delete("`").split(".")

        case identifiers.length
        when 1
          Nodes::TypeInfo.new(identifiers.first, nil)
        when 2
          Nodes::TypeInfo.new(identifiers[1], identifiers[0])
        else
          raise Fhirpath::Error, "Expected TypeSpecifier node, got #{node}"
        end
      end

      def build_expr_param(ctx, param)
        lambda do |data|
          ctx[:this] = Util.arraify(data)
          do_eval(ctx, ctx[:this], param)
        end
      end

      def eval_param(ctx, data, param)
        ctx[:this] = data
        do_eval(ctx, data, param)
      end
    end
  end
end
