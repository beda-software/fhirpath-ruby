# frozen_string_literal: true

module Fhirpath
  module Engine
    module Invocations
      # `~`/`!~` from fhirpath-py's fhirpathpy/engine/invocations/equality.py. Split out of
      # equality.rb to keep that file's module body short; reopens the same Equality module
      # (datetime_value?/datetime_equals/coerce_datetime are defined there).
      module Equality
        class << self
          def equival(_ctx, left, right)
            result = equivalence(left, right)
            result.nil? ? [false] : [result]
          end

          def unequival(_ctx, left, right)
            result = equivalence(left, right)
            result.nil? ? [true] : [!result]
          end

          private

          # Per https://hl7.org/fhirpath/#equivalence. Unlike `=`, `{} ~ {}` is true, and a
          # DateTime/Time precision mismatch is handled by the `[false]`/`[true]` fallback above
          # rather than staying empty. Collections with more than one item are compared as a
          # multiset (order-independent) — fhirpath-py's own equivalence() only ever compares
          # the first pair once both collections are the same Mapping/list-shaped type, a
          # narrower reading no test here happens to probe (see equality.rb's `equality` for the
          # analogous `=` case).
          def equivalence(left, right)
            both_empty = equivalence_for_empty(left, right)
            return both_empty unless both_empty.nil?

            return false if left.length != right.length

            x0 = Util.val_data_converted(left.first)
            y0 = Util.val_data_converted(right.first)
            return datetime_equals(x0, y0) if datetime_value?(x0) || datetime_value?(y0)

            left.length == 1 ? value_equivalent?(x0, y0) : multiset_equivalent?(left, right)
          end

          def equivalence_for_empty(left, right)
            return true if Util.empty?(left) && Util.empty?(right)
            return false if Util.empty?(left) || Util.empty?(right)

            nil
          end

          def multiset_equivalent?(left, right)
            remaining = right.map { |item| Util.val_data_converted(item) }

            left.all? do |item|
              value = Util.val_data_converted(item)
              index = remaining.index { |candidate| value_equivalent?(value, candidate) == true }
              next false unless index

              remaining.delete_at(index)
              true
            end
          end

          def value_equivalent?(left, right)
            return normalize_string(left) == normalize_string(right) if both_strings?(left, right)
            return numbers_equivalent?(left, right) if left.is_a?(::BigDecimal) || right.is_a?(::BigDecimal)
            return left.deep_equal(right) if both_quantities?(left, right)
            return deep_equivalent?(left, right) if collection_like?(left) && collection_like?(right)

            left == right
          end

          def both_strings?(left, right)
            left.is_a?(::String) && right.is_a?(::String)
          end

          def both_quantities?(left, right)
            left.is_a?(Nodes::FPQuantity) && right.is_a?(Nodes::FPQuantity)
          end

          def collection_like?(value)
            value.is_a?(::Hash) || value.is_a?(::Array)
          end

          # Structural equivalence: hash keys compared as sets (order-independent), array
          # elements compared as a sorted sequence, strings via normalize_string, and numbers
          # within a small tolerance — mirrors fhirpath-py's nested deep_equal.
          def deep_equivalent?(left, right)
            case left
            when ::Hash then hashes_equivalent?(left, right)
            when ::Array then arrays_equivalent?(left, right)
            when ::String then right.is_a?(::String) && normalize_string(left) == normalize_string(right)
            when ::Numeric then right.is_a?(::Numeric) && (left - right).abs < 0.5
            else left == right
            end
          end

          def hashes_equivalent?(left, right)
            return false unless right.is_a?(::Hash) && left.keys.sort == right.keys.sort

            left.keys.all? { |key| deep_equivalent?(left[key], right[key]) }
          end

          def arrays_equivalent?(left, right)
            return false unless right.is_a?(::Array) && left.length == right.length

            sort_for_compare(left).zip(sort_for_compare(right)).all? { |x, y| deep_equivalent?(x, y) }
          end

          def sort_for_compare(array)
            array.sort
          rescue ::ArgumentError
            array.sort_by(&:to_s)
          end

          def normalize_string(value)
            value.downcase.split.join(" ")
          end

          # Values are compared rounded to the precision of the less-precise operand (trailing
          # zeroes don't count as precision) — https://hl7.org/fhirpath/#equivalence.
          def numbers_equivalent?(left, right)
            places = [decimal_places(left), decimal_places(right)].min
            return Util.to_big_decimal(left).round == Util.to_big_decimal(right).round if places.zero?

            Util.to_big_decimal(left).round(places) == Util.to_big_decimal(right).round(places)
          end

          def decimal_places(value)
            str = Util.to_big_decimal(value).to_s("F")
            return 0 unless str.include?(".")

            str.split(".").last.sub(/0+\z/, "").length
          end
        end
      end
    end
  end
end
