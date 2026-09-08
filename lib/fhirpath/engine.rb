# frozen_string_literal: true

require_relative "engine/nodes/resource_node"
require_relative "engine/nodes/fp_quantity"
require_relative "engine/nodes/fp_date_time"
require_relative "engine/nodes/fp_time"
require_relative "engine/nodes/type_info"
require_relative "engine/util"
require_relative "engine/invocations"
require_relative "engine/evaluators"
require_relative "engine/param_resolution"

module Fhirpath
  # Ruby port of fhirpath-py's fhirpathpy/engine/__init__.py: walks the AST built by
  # Fhirpath::Parser (see Evaluators::DISPATCH for the per-node-type evaluators) and dispatches
  # function/operator calls to Invocations::REGISTRY.
  module Engine
    class << self
      def do_eval(ctx, parent_data, node)
        evaluator = Evaluators::DISPATCH[node["type"]]
        raise Fhirpath::Error, "No #{node["type"]} evaluator" unless evaluator

        evaluator.call(ctx, parent_data, node)
      end

      def do_invoke(ctx, fn_name, data, raw_params)
        fn_name, invocation = lookup_invocation(ctx, fn_name)
        return [] if invocation[:nullable_input] && Util.nullable?(data)
        return invoke_variadic(ctx, invocation, data, raw_params) if invocation[:variadic]
        return call_niladic(ctx, fn_name, invocation, data, raw_params) unless invocation[:arity]

        invoke_with_arity(ctx, fn_name, invocation, data, raw_params)
      end

      def infix_invoke(ctx, fn_name, data, raw_params)
        invocation = invocation_registry(ctx)[fn_name]
        raise Fhirpath::Error, "Not implemented #{fn_name}" unless invocation&.fetch(:fn, nil)
        raise Fhirpath::Error, "Infix invoke should have arity 2" if raw_params.length != 2

        params = [ctx] + positional_params(ctx, data, invocation[:arity][2], raw_params, 2)
        call_invocation(invocation, params)
      end

      private

      def lookup_invocation(ctx, fn_name)
        registry = invocation_registry(ctx)
        fn_name = fn_name.first if fn_name.is_a?(::Array) && fn_name.length == 1
        raise Fhirpath::Error, "Not implemented: #{fn_name}" unless fn_name.is_a?(::String) && registry.key?(fn_name)

        [fn_name, registry[fn_name]]
      end

      def call_niladic(ctx, fn_name, invocation, data, raw_params)
        raise Fhirpath::Error, "#{fn_name} expects no params" unless raw_params.nil? || Util.empty?(raw_params)

        Util.arraify(invocation[:fn].call(ctx, Util.arraify(data)))
      end

      def invoke_variadic(ctx, invocation, data, raw_params)
        raw_params_list = raw_params.is_a?(::Array) ? raw_params : []
        this_value = ctx[:this] || ctx[:root]
        params = raw_params_list.map { |param| make_param(ctx, this_value, invocation[:variadic], param) }

        Util.arraify(invocation[:fn].call(ctx, Util.arraify(data), *params))
      end

      def invoke_with_arity(ctx, fn_name, invocation, data, raw_params)
        params_number = raw_params.is_a?(::Array) ? raw_params.length : 0
        unless invocation[:arity].key?(params_number)
          raise Fhirpath::Error,
                "#{fn_name} wrong arity: got #{params_number}"
        end

        this_value = ctx[:this] || ctx[:root]
        arg_types = invocation[:arity][params_number]
        params = [ctx, data] + positional_params(ctx, this_value, arg_types, raw_params, params_number)

        call_invocation(invocation, params)
      end

      def call_invocation(invocation, params)
        return [] if invocation[:nullable] && params.any? { |param| Util.nullable?(param) }

        Util.arraify(invocation[:fn].call(*params))
      end

      def positional_params(ctx, base_data, arg_types, raw_params, count)
        (0...count).map { |i| make_param(ctx, base_data, arg_types[i], raw_params[i]) }
      end

      def invocation_registry(ctx)
        Invocations::REGISTRY.merge(ctx[:user_invocation_table] || {})
      end
    end
  end
end
