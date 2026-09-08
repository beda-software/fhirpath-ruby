# frozen_string_literal: true

require_relative "existence"

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of `combine`/`union_op`/`coalesce_fn` from fhirpath-py's
      # fhirpathpy/engine/invocations/combining.py.
      module Combining
        def self.combine(_ctx, coll1, coll2)
          coll1 + coll2
        end

        def self.union(ctx, coll1, coll2)
          Existence.distinct(ctx, coll1 + coll2)
        end

        def self.coalesce(_ctx, data, *exprs)
          exprs.each do |expr|
            result = expr.call(data)
            return result unless Util.empty?(result)
          end

          []
        end
      end
    end
  end
end
