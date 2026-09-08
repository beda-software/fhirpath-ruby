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

        def true?(value)
          value == true || (value.is_a?(::Array) && value.length == 1 && value.first == true)
        end

        # Dedupes values that compare equal after normalizing hash key order (so
        # `{"a"=>1,"b"=>2}` and `{"b"=>2,"a"=>1}` collapse together), preserving first-seen
        # order — mirrors fhirpath-py's util.uniq (JSON-with-sorted-keys as the dedup key).
        def uniq(values)
          seen = {}
          values.each_with_object([]) do |value, acc|
            key = canonical_key(value)
            next if seen[key]

            seen[key] = true
            acc << value
          end
        end

        private

        def canonical_key(value)
          sorted_keys(value).to_s
        rescue ::StandardError
          value.to_s
        end

        def sorted_keys(value)
          case value
          when ::Hash
            value.keys.sort_by(&:to_s).each_with_object({}) { |k, h| h[k] = sorted_keys(value[k]) }
          when ::Array
            value.map { |v| sorted_keys(v) }
          else
            value
          end
        end
      end
    end
  end
end
