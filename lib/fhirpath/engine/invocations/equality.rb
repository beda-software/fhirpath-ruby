# frozen_string_literal: true

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of `=` from fhirpath-py's fhirpathpy/engine/invocations/equality.py. Only the
      # plain-value comparison needed for `where()` filters on path expressions is ported so
      # far; FP_Quantity/FP_DateTime-aware comparison isn't exercised yet.
      module Equality
        class << self
          def equal(_ctx, left, right)
            return false if Util.empty?(left) || Util.empty?(right)
            return false if left.length != right.length

            Util.get_data(left[0]) == Util.get_data(right[0])
          end
        end
      end
    end
  end
end
