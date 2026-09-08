# frozen_string_literal: true

require_relative "math"

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of fhirpath-py's fhirpathpy/engine/invocations/aggregate.py (FHIRPath spec
      # section 7).
      module Aggregate
        class << self
          # `$total`/`$index` (see Evaluators.total_invocation/index_invocation) read
          # ctx[:total]/ctx[:index], which this loop maintains for `expr` to see.
          def aggregate(ctx, data, expr, initial_value = [])
            ctx[:total] = initial_value
            Util.arraify(data).each_with_index do |item, index|
              ctx[:index] = index
              ctx[:total] = expr.call(item)
            end
            ctx[:total]
          end

          def sum(_ctx, coll)
            coll.sum
          end

          def avg(ctx, coll)
            return [] if coll.empty?

            Math.div(ctx, sum(ctx, coll), coll.length)
          end

          def min(_ctx, coll)
            return [] if coll.empty?

            coll.min
          end

          def max(_ctx, coll)
            return [] if coll.empty?

            coll.max
          end
        end
      end
    end
  end
end
