# frozen_string_literal: true

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of `and`/`or`/`xor`/`implies` from fhirpath-py's
      # fhirpathpy/engine/invocations/logic.py (three-valued Boolean logic — each operand is
      # `true`, `false`, or `[]` for empty, per https://hl7.org/fhirpath/#boolean-logic).
      module Logic
        class << self
          def or_op(_ctx, left, right)
            return or_with_empty_right(left) if right.is_a?(::Array)
            return or_with_empty_left(right) if left.is_a?(::Array)

            left || right
          end

          def and_op(_ctx, left, right)
            return and_with_empty_right(left) if right.is_a?(::Array)
            return and_with_empty_left(right) if left.is_a?(::Array)

            left && right
          end

          def xor_op(_ctx, left, right)
            return [] if left.is_a?(::Array) || right.is_a?(::Array)

            (left && !right) || (!left && right)
          end

          def implies_op(_ctx, left, right)
            return implies_with_empty_right(left) if right.is_a?(::Array)
            return implies_with_empty_left(right) if left.is_a?(::Array)
            return true if left == false

            left && right
          end

          private

          def or_with_empty_right(left)
            return true if left == true

            []
          end

          def or_with_empty_left(right)
            right == true ? true : []
          end

          def and_with_empty_right(left)
            return false if left == false

            []
          end

          def and_with_empty_left(right)
            right == true ? [] : false
          end

          def implies_with_empty_right(left)
            return true if left == false

            []
          end

          def implies_with_empty_left(right)
            right == true ? true : []
          end
        end
      end
    end
  end
end
