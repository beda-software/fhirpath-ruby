# frozen_string_literal: true

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of `=`/`<`/`>` from fhirpath-py's fhirpathpy/engine/invocations/equality.py.
      # Only the plain-value comparison needed so far is ported; FP_Quantity/FP_DateTime-aware
      # inequality comparison (typecheck's coercion) isn't exercised yet.
      module Equality
        class << self
          def equal(_ctx, left, right)
            return false if Util.empty?(left) || Util.empty?(right)
            return false if left.length != right.length

            Util.get_data(left[0]) == Util.get_data(right[0])
          end

          def gt(_ctx, left, right)
            Util.get_data(left[0]) > Util.get_data(right[0])
          end

          def lt(_ctx, left, right)
            Util.get_data(left[0]) < Util.get_data(right[0])
          end
        end
      end
    end
  end
end
