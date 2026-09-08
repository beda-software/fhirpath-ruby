# frozen_string_literal: true

module Fhirpath
  module Engine
    module Invocations
      # `<`/`>`/`<=`/`>=` from fhirpath-py's fhirpathpy/engine/invocations/equality.py
      # (typecheck/lt/gt/lte/gte). Split out of equality.rb to keep that file's module body
      # short; reopens the same Equality module (datetime_value?/coerce_datetime are defined
      # there).
      module Equality
        class << self
          def lt(_ctx, left, right)
            compare(left, right) { |ordinal| ordinal == -1 }
          end

          def gt(_ctx, left, right)
            compare(left, right) { |ordinal| ordinal == 1 }
          end

          def lte(_ctx, left, right)
            compare(left, right) { |ordinal| ordinal <= 0 }
          end

          def gte(_ctx, left, right)
            compare(left, right) { |ordinal| ordinal >= 0 }
          end

          private

          # Per https://hl7.org/fhirpath/#comparison. Returns [] for an empty operand or a
          # DateTime/Time comparison that can't be resolved at a shared precision.
          def compare(left, right)
            return [] if Util.empty?(left) || Util.empty?(right)

            left_value, right_value = typecheck(left, right)
            ordinal = ordinal_compare(left_value, right_value)
            return [] if ordinal.nil?

            yield ordinal
          end

          def ordinal_compare(left_value, right_value)
            return left_value.compare(right_value) if datetime_value?(left_value)

            left_value <=> right_value
          end

          # Singleton-checks both sides and requires them to be the same type (numbers are
          # cross-comparable regardless of exact class); a string compared against a
          # DateTime/Time is itself parsed as one first.
          def typecheck(left, right)
            left = Util.remove_duplicate_extension(left)
            right = Util.remove_duplicate_extension(right)
            check_length(left)
            check_length(right)

            a = Util.get_data(left.first)
            b = Util.get_data(right.first)
            return [a, b] if a.instance_of?(b.class) || (a.is_a?(::Numeric) && b.is_a?(::Numeric))

            coerce_mismatched_types(a, b) || raise_type_mismatch(a, b)
          end

          def check_length(coll)
            return unless coll.length > 1

            raise Fhirpath::Error,
                  "Was expecting no more than one element but got #{coll.inspect}. Singleton was expected"
          end

          def coerce_mismatched_types(left, right)
            return coerce_left_string(left, right) if left.is_a?(::String) && datetime_value?(right)
            return coerce_left_string(right, left)&.reverse if right.is_a?(::String) && datetime_value?(left)

            nil
          end

          def coerce_left_string(string_value, datetime)
            coerced = coerce_datetime(string_value)
            coerced ? [coerced, datetime] : nil
          end

          def raise_type_mismatch(left, right)
            raise Fhirpath::Error,
                  "Type of \"#{left}\" (#{left.class}) did not match type of \"#{right}\" (#{right.class}). " \
                  "InequalityExpression"
          end
        end
      end
    end
  end
end
