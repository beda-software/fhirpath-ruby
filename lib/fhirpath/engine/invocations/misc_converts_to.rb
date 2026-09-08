# frozen_string_literal: true

require "bigdecimal"

module Fhirpath
  module Engine
    module Invocations
      # Reopens Misc (see misc.rb) to add `toBoolean`/the convertsTo* family, ported from
      # fhirpath-py's fhirpathpy/engine/invocations/misc.py.
      module Misc
        class << self
          TRUE_STRINGS = %w[true t yes y 1 1.0].freeze
          FALSE_STRINGS = %w[false f no n 0 0.0].freeze

          # Unlike the other to_* conversions, this checks the raw collection item's own type
          # directly (not Util.get_data-unwrapped) — mirrors fhirpath-py's to_boolean.
          def to_boolean(_ctx, coll)
            return [] if coll.length != 1

            value = coll.first
            return value if [true, false].include?(value)
            return boolean_from_number(value) if value.is_a?(::Numeric)
            return boolean_from_string(value) if value.is_a?(::String)

            []
          end

          # Ports fhirpath-py's create_converts_to_fn: the collection must be a singleton, and
          # the conversion must both succeed (not fall back to `[]`) and produce a value of the
          # expected Ruby class.
          def converts_to?(ctx, coll, expected_class, &converter)
            return [] if coll.length != 1

            converter.call(ctx, coll).is_a?(expected_class)
          end

          def converts_to_boolean(ctx, coll)
            return [] if coll.length != 1

            [true, false].include?(to_boolean(ctx, coll))
          end

          def converts_to_integer(ctx, coll)
            converts_to?(ctx, coll, ::Integer) { |c, co| to_integer(c, co) }
          end

          def converts_to_decimal(ctx, coll)
            converts_to?(ctx, coll, ::BigDecimal) { |c, co| to_decimal(c, co) }
          end

          def converts_to_string(ctx, coll)
            converts_to?(ctx, coll, ::String) { |c, co| to_string(c, co) }
          end

          def converts_to_date(ctx, coll)
            converts_to?(ctx, coll, Nodes::FPDateTime) { |c, co| to_date(c, co) }
          end

          def converts_to_date_time(ctx, coll)
            converts_to?(ctx, coll, Nodes::FPDateTime) { |c, co| to_date_time(c, co) }
          end

          def converts_to_time(ctx, coll)
            converts_to?(ctx, coll, Nodes::FPTime) { |c, co| to_time(c, co) }
          end

          def converts_to_quantity(ctx, coll)
            converts_to?(ctx, coll, Nodes::FPQuantity) { |c, co| to_quantity(c, co) }
          end

          private

          def boolean_from_number(value)
            return true if [1, 1.0].include?(value)
            return false if [0, 0.0].include?(value)

            []
          end

          def boolean_from_string(value)
            lower = value.downcase
            return true if TRUE_STRINGS.include?(lower)
            return false if FALSE_STRINGS.include?(lower)

            []
          end
        end
      end
    end
  end
end
