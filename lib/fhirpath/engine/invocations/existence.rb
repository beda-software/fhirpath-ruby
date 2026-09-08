# frozen_string_literal: true

require_relative "filtering"

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of fhirpath-py's fhirpathpy/engine/invocations/existence.py (FHIRPath spec
      # section 5.1).
      module Existence
        class << self
          def empty(_ctx, value)
            Util.empty?(value)
          end

          def count(_ctx, value)
            value.is_a?(::Array) ? value.length : 0
          end

          def not(_ctx, coll)
            return [] if coll.empty?

            if coll.length > 1
              raise Fhirpath::Error, "Unexpected collection #{coll.inspect}; expected singleton of type Boolean"
            end

            !singleton_truthy?(coll.first)
          end

          def exists(ctx, coll, expr = nil)
            return !Util.empty?(coll) if expr.nil?

            exists(ctx, Filtering.where(ctx, coll, expr))
          end

          def all(ctx, colls, expr)
            colls.each_with_index do |coll, index|
              ctx[:index] = index
              return [false] unless Util.true?(expr.call(coll))
            end

            [true]
          end

          def all_true(_ctx, items)
            items.all? { |item| boolean_value(item) }
          end

          def any_true(_ctx, items)
            items.any? { |item| boolean_value(item) }
          end

          def all_false(_ctx, items)
            items.all? { |item| !boolean_value(item) }
          end

          def any_false(_ctx, items)
            items.any? { |item| !boolean_value(item) }
          end

          def subset_of(_ctx, coll1, coll2)
            coll1.all? { |item| coll2.include?(item) }
          end

          def superset_of(ctx, coll1, coll2)
            subset_of(ctx, coll2, coll1)
          end

          def distinct?(ctx, coll)
            coll.length == distinct(ctx, coll).length
          end

          def distinct(_ctx, coll)
            return distinct_resource_nodes(coll) if coll.any? && coll.all? { |v| v.is_a?(Nodes::ResourceNode) }
            return distinct_quantities(coll) if coll.any? && coll.all? { |v| v.is_a?(Nodes::FPQuantity) }

            Util.uniq(coll)
          end

          private

          def boolean_value(item)
            value = Util.get_data(item)
            raise Fhirpath::Error, "Expected boolean, but got: #{value.inspect}" unless [true, false].include?(value)

            value
          end

          # Mirrors fhirpath-py's boolean_singleton (used only by `not`, unlike the strict
          # boolean_value above used by allTrue/anyTrue/allFalse/anyFalse): a present non-empty
          # singleton coerces to `true` unless it's literally the boolean `false`.
          def singleton_truthy?(item)
            value = Util.get_data(item)
            [true, false].include?(value) ? value : true
          end

          def distinct_resource_nodes(coll)
            Util.uniq(coll.map(&:data)).map { |item| Nodes::ResourceNode.create_node(item) }
          end

          # FP_Quantity#== already treats e.g. "1 year" and "12 months" as equal
          # (https://hl7.org/fhirpath/#equals); dedupe with a linear scan since quantities
          # aren't otherwise hashable/canonicalizable the way Util.uniq's values are.
          def distinct_quantities(coll)
            coll.each_with_object([]) { |value, acc| acc << value unless acc.include?(value) }
          end
        end
      end
    end
  end
end
