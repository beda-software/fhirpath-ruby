# frozen_string_literal: true

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of `combine` from fhirpath-py's fhirpathpy/engine/invocations/combining.py.
      module Combining
        def self.combine(ctx, data, other_node)
          base = ctx[:this] || ctx[:root]
          data + Engine.do_eval(ctx, base, other_node)
        end
      end
    end
  end
end
