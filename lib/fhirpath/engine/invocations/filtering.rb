# frozen_string_literal: true

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of `where` from fhirpath-py's fhirpathpy/engine/invocations/filtering.py.
      module Filtering
        class << self
          def where(ctx, data, expr)
            return [] unless data.is_a?(::Array)

            result = data.each_with_index.select do |item, index|
              ctx[:index] = index
              truthy?(expr.call(item))
            end.map(&:first)

            Util.flatten(result)
          end

          private

          def truthy?(result)
            return false if result.empty?

            value = result.first
            !(value.nil? || value == false)
          end
        end
      end
    end
  end
end
