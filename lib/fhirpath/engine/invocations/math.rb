# frozen_string_literal: true

require "bigdecimal"
require "bigdecimal/math"

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of `+`/`abs`/`ceiling`/`exp`/`floor`/`ln`/`log`/`power`/`round`/`sqrt`/
      # `truncate` from fhirpath-py's fhirpathpy/engine/invocations/math.py. `-`/`*`/`/`/`div`/
      # `mod`/`&` and FP_TimeBase/FP_Quantity arithmetic aren't exercised yet.
      module Math
        LOG_PRECISION = 30
        LOG_SCALE = 15

        class << self
          def plus(_ctx, left, right)
            raise Fhirpath::Error, "Cannot #{left} + #{right}" if left.length != 1 || right.length != 1

            x = Util.get_data(left[0])
            y = Util.get_data(right[0])

            return x + y if (x.is_a?(::String) && y.is_a?(::String)) || (x.is_a?(::Numeric) && y.is_a?(::Numeric))

            raise Fhirpath::Error, "Cannot #{left} + #{right}"
          end

          def abs(_ctx, num)
            return [] if blank?(num)

            ensure_number_singleton(num).abs
          end

          def ceiling(_ctx, num)
            return [] if blank?(num)

            ensure_number_singleton(num).ceil
          end

          def floor(_ctx, num)
            return [] if blank?(num)

            ensure_number_singleton(num).floor
          end

          def truncate(_ctx, num)
            return [] if blank?(num)

            ensure_number_singleton(num).truncate
          end

          def exp(_ctx, num)
            return [] if blank?(num)

            BigMath.exp(Util.to_big_decimal(ensure_number_singleton(num)), LOG_PRECISION)
          end

          def ln(_ctx, num)
            return [] if blank?(num)

            BigMath.log(Util.to_big_decimal(ensure_number_singleton(num)), LOG_PRECISION)
          end

          def log(_ctx, num, base)
            return [] if blank?(num) || blank?(base)

            value = Util.to_big_decimal(ensure_number_singleton(num))
            base_value = Util.to_big_decimal(ensure_number_singleton(base))

            (BigMath.log(value, LOG_PRECISION) / BigMath.log(base_value, LOG_PRECISION)).round(LOG_SCALE)
          end

          def sqrt(_ctx, num)
            return [] if blank?(num)

            value = ensure_number_singleton(num)
            return [] if value.negative?

            Util.to_big_decimal(value).sqrt(LOG_PRECISION)
          end

          def power(_ctx, num, degree)
            return [] if blank?(num) || blank?(degree)

            base = ensure_number_singleton(num)
            exponent = ensure_number_singleton(degree)
            return [] if base.negative? || exponent.to_i != exponent

            base**exponent
          end

          def round(_ctx, num, precision)
            return [] if blank?(num)

            value = ensure_number_singleton(num)
            return value.round if blank?(precision)

            value.round(ensure_number_singleton(precision).to_i)
          end

          private

          # Mirrors fhirpath-py's is_empty: the argument may be the raw input collection
          # (always an array) or an already-resolved param value (a raw number, or `[]` if the
          # param expression itself was empty).
          def blank?(value)
            return false if value.is_a?(::Numeric)

            Util.empty?(value)
          end

          # Mirrors fhirpath-py's ensure_number_singleton: accepts either a raw number
          # (an already-resolved param) or a singleton collection (the raw input data).
          def ensure_number_singleton(value)
            data = Util.get_data(value)
            return data if data.is_a?(::Numeric)

            unless data.is_a?(::Array) && data.length == 1
              raise Fhirpath::Error, "Expected list with number, but got #{data.inspect}"
            end

            item = Util.get_data(data.first)
            raise Fhirpath::Error, "Expected number, but got #{value.inspect}" unless item.is_a?(::Numeric)

            item
          end
        end
      end
    end
  end
end
