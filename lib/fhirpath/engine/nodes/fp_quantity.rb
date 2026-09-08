# frozen_string_literal: true

module Fhirpath
  module Engine
    module Nodes
      # Minimal Ruby port of fhirpath-py's FP_Quantity (fhirpathpy/engine/nodes.py), covering
      # only what quantity *literals* currently need: printing back as "value unit" and
      # exposing `.value` through member invocation.
      class FPQuantity
        attr_reader :value, :unit

        def initialize(value, unit)
          @value = value
          @unit = unit
        end

        def to_s
          "#{value} #{unit}"
        end
      end
    end
  end
end
