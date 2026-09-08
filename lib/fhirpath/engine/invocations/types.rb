# frozen_string_literal: true

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of `is`/`as` from fhirpath-py's fhirpathpy/engine/invocations/types.py.
      # `type()` isn't exercised yet.
      module Types
        class << self
          def is(ctx, coll, type_info)
            return [] if coll.empty?
            raise Fhirpath::Error, "Expected singleton on left side of 'is', got #{coll.inspect}" if coll.length > 1

            Nodes::TypeInfo.from_value(coll.first, ctx[:model]).is_(type_info, ctx[:model])
          end

          def as(ctx, coll, type_info)
            return [] if coll.empty?
            raise Fhirpath::Error, "Expected singleton on left side of 'as', got #{coll.inspect}" if coll.length > 1

            Nodes::TypeInfo.from_value(coll.first, ctx[:model]).is_(type_info, ctx[:model]) ? coll : []
          end
        end
      end
    end
  end
end
