# frozen_string_literal: true

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of `+` from fhirpath-py's fhirpathpy/engine/invocations/math.py. Only
      # number/string addition is ported so far; FP_TimeBase/FP_Quantity arithmetic isn't
      # exercised yet.
      module Math
        def self.plus(_ctx, left, right)
          raise Fhirpath::Error, "Cannot #{left} + #{right}" if left.length != 1 || right.length != 1

          x = Util.get_data(left[0])
          y = Util.get_data(right[0])

          return x + y if (x.is_a?(::String) && y.is_a?(::String)) || (x.is_a?(::Numeric) && y.is_a?(::Numeric))

          raise Fhirpath::Error, "Cannot #{left} + #{right}"
        end
      end
    end
  end
end
