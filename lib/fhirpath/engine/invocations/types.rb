# frozen_string_literal: true

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of `is`/`as`/`type` from fhirpath-py's fhirpathpy/engine/invocations/types.py.
      module Types
        class << self
          # Each item's TypeInfo, as a plain Hash so ".name"/".namespace" member navigation
          # (see evaluators/member_invocation.rb's generic Hash handling) works on the result —
          # mirrors fhirpath-py's type_fn returning TypeInfo.__dict__ for each value.
          def type(ctx, coll)
            coll.map do |item|
              type_info = Nodes::TypeInfo.from_value(item, ctx[:model])
              { "name" => type_info.name, "namespace" => type_info.namespace }
            end
          end

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
