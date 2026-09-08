# frozen_string_literal: true

module Fhirpath
  module Engine
    # Ruby port of fhirpath-py's fhirpathpy/engine/util.py: small helpers shared across the
    # evaluator, invocation dispatch, and invocation implementations.
    module Util
      class << self
        def get_data(value)
          value.is_a?(Nodes::ResourceNode) ? value.data : value
        end

        def capitalized?(value)
          value.is_a?(::String) && !value.empty? && value[0] == value[0].upcase
        end

        def empty?(value)
          value.is_a?(::Array) && value.empty?
        end

        def some?(value)
          !value.nil? && !empty?(value)
        end

        def nullable?(value)
          value.nil? || empty?(value)
        end

        def arraify(value, instead_none = nil)
          return value if value.is_a?(::Array)
          return [value] if some?(value)

          instead_none.nil? ? [] : [instead_none]
        end

        def flatten(values)
          values.each_with_object([]) do |value, acc|
            value.is_a?(::Array) ? acc.concat(value) : acc << value
          end
        end
      end
    end
  end
end
