# frozen_string_literal: true

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of `contains`/`in` from fhirpath-py's
      # fhirpathpy/engine/invocations/collections.py (FHIRPath spec 6.4.2/6.4.3).
      module Collections
        class << self
          def contains(_ctx, coll, item)
            return [] if item.empty?
            return false if coll.empty?
            if item.length > 1
              raise Fhirpath::Error,
                    "Expected singleton on right side of contains, got #{item.inspect}"
            end

            coll.include?(item.first)
          end

          def in(_ctx, coll, other)
            return [] if coll.empty?
            return false if other.empty?
            raise Fhirpath::Error, "Expected singleton on right side of in, got #{coll.inspect}" if coll.length > 1

            other.include?(coll.first)
          end
        end
      end
    end
  end
end
