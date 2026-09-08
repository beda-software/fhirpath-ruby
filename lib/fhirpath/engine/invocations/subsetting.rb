# frozen_string_literal: true

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of `intersect` from fhirpath-py's fhirpathpy/engine/invocations/subsetting.py.
      module Subsetting
        def self.intersect(_ctx, coll1, coll2)
          intersection = coll1.select { |item| coll2.include?(item) }
          intersection.each_with_object([]) { |item, acc| acc << item unless acc.include?(item) }
        end
      end
    end
  end
end
