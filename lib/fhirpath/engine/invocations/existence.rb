# frozen_string_literal: true

require "bigdecimal"

require_relative "filtering"

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of fhirpath-py's fhirpathpy/engine/invocations/existence.py (FHIRPath spec
      # section 5.1).
      module Existence
        # Time/calendar-duration units that convert to a common scale, used by `distinct` to
        # treat e.g. "1 year" and "12 months" as equal (https://hl7.org/fhirpath/#equals).
        CONVERSION_FACTORS = {
          "weeks" => BigDecimal("604800000"), "'wk'" => BigDecimal("604800000"), "week" => BigDecimal("604800000"),
          "days" => BigDecimal("86400000"), "'d'" => BigDecimal("86400000"), "day" => BigDecimal("86400000"),
          "hours" => BigDecimal("3600000"), "'h'" => BigDecimal("3600000"), "hour" => BigDecimal("3600000"),
          "minutes" => BigDecimal("60000"), "'min'" => BigDecimal("60000"), "minute" => BigDecimal("60000"),
          "seconds" => BigDecimal("1000"), "'s'" => BigDecimal("1000"), "second" => BigDecimal("1000"),
          "milliseconds" => BigDecimal("1"), "'ms'" => BigDecimal("1"), "millisecond" => BigDecimal("1"),
          "years" => BigDecimal("12"), "'a'" => BigDecimal("12"), "year" => BigDecimal("12"),
          "months" => BigDecimal("1"), "'mo'" => BigDecimal("1"), "month" => BigDecimal("1")
        }.freeze

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

            !boolean_value(coll.first)
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

          def distinct_resource_nodes(coll)
            Util.uniq(coll.map(&:data)).map { |item| Nodes::ResourceNode.create_node(item) }
          end

          # Dedupes by converting each quantity onto a common scale (see CONVERSION_FACTORS),
          # keeping the first-seen original quantity per distinct converted value; a quantity
          # whose unit isn't in CONVERSION_FACTORS is dropped, matching fhirpath-py.
          def distinct_quantities(coll)
            converted = {}

            coll.each do |interval|
              factor = CONVERSION_FACTORS[interval.unit]
              next unless factor

              converted[interval.value * factor] ||= interval
            end

            converted.values
          end
        end
      end
    end
  end
end
