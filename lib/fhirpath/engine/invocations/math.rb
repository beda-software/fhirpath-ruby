# frozen_string_literal: true

require "bigdecimal"
require_relative "math_functions"

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of `+`/`-`/`*`/`/`/`div`/`mod`/`&` from fhirpath-py's
      # fhirpathpy/engine/invocations/math.py, including FP_TimeBase/FP_Quantity date
      # arithmetic (`+`/`-` between a date/time and a duration quantity). The single-argument
      # numeric functions (`abs`/`ceiling`/`exp`/`floor`/`ln`/`log`/`power`/`round`/`sqrt`/
      # `truncate`) live in math_functions.rb, reopening this same module.
      module Math
        # Matches Python's decimal module's default context precision (28 significant digits),
        # which is what fhirpath-py's `/` division relies on implicitly — Ruby's BigDecimal `/`
        # has no such fixed precision by default, so without this e.g. `1.2 / 1.8` produces a
        # different (longer, differently-rounded) repeating decimal than the reference.
        DECIMAL_PRECISION = 28

        class << self
          def plus(_ctx, left, right)
            lhs, rhs = resolve_operands(left, right, "+")

            return lhs + rhs if (lhs.is_a?(::String) && rhs.is_a?(::String)) ||
                                (lhs.is_a?(::Numeric) && rhs.is_a?(::Numeric))

            date_time_plus(lhs, rhs) { raise Fhirpath::Error, "Cannot #{left} + #{right}" }
          end

          def minus(_ctx, left, right)
            lhs, rhs = resolve_operands(left, right, "-")

            return lhs - rhs if lhs.is_a?(::Numeric) && rhs.is_a?(::Numeric)

            rhs = Nodes::FPQuantity.new(-rhs.value, rhs.unit) if rhs.is_a?(Nodes::FPQuantity)
            date_time_plus(lhs, rhs) { raise Fhirpath::Error, "Cannot #{left} - #{right}" }
          end

          def mul(_ctx, lhs, rhs)
            lhs * rhs
          end

          def div(_ctx, lhs, rhs)
            return [] if rhs.zero?

            Util.to_big_decimal(lhs).div(Util.to_big_decimal(rhs), DECIMAL_PRECISION)
          end

          def intdiv(_ctx, lhs, rhs)
            return [] if rhs.zero?

            Util.to_big_decimal(lhs).div(Util.to_big_decimal(rhs), DECIMAL_PRECISION).truncate
          end

          def mod(_ctx, lhs, rhs)
            return [] if rhs.zero?

            lhs % rhs
          end

          def amp(_ctx, lhs, rhs)
            lhs = "" if lhs == []
            rhs = "" if rhs == []
            lhs + rhs
          end

          private

          # Mirrors fhirpath-py's own `xs = remove_duplicate_extension(xs_)` at the top of
          # `plus`/`minus`: strip the "Cannot ... " length check down to the primitive operand,
          # then unwrap it from its ResourceNode.
          def resolve_operands(left, right, operator)
            left = Util.remove_duplicate_extension(left)
            right = Util.remove_duplicate_extension(right)
            raise Fhirpath::Error, "Cannot #{left} #{operator} #{right}" if left.length != 1 || right.length != 1

            [Util.get_data(left[0]), Util.get_data(right[0])]
          end

          # A duration quantity added to (or, via `minus`, subtracted from) a date/time value —
          # https://hl7.org/fhirpath/#datetime-arithmetic. `lhs` may already be an FPDateTime/
          # FPTime (e.g. the left side was itself a date/time literal), or a raw String that
          # happens to be date/time-shaped (e.g. a FHIR "date"/"dateTime"/"time" element's raw
          # value navigated without a model, so it was never converted to an FP_* type) — either
          # way, if it parses as a date/time and `rhs` is a quantity, delegate to its `#plus`.
          def date_time_plus(lhs, rhs)
            return yield unless rhs.is_a?(Nodes::FPQuantity)

            target = lhs.is_a?(::String) ? coerce_date_or_time(lhs) : lhs
            return yield unless target.is_a?(Nodes::FPDateTime) || target.is_a?(Nodes::FPTime)

            target.plus(rhs)
          end

          def coerce_date_or_time(str)
            Nodes::FPDateTime.new(str)
          rescue Fhirpath::Error
            begin
              Nodes::FPTime.new(str)
            rescue Fhirpath::Error
              nil
            end
          end
        end
      end
    end
  end
end
