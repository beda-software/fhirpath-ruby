# frozen_string_literal: true

module Fhirpath
  module Engine
    module Nodes
      # Ruby port of fhirpath-py's ResourceNode (fhirpathpy/engine/nodes.py): wraps a node of
      # data reached while navigating a resource, tracking its FHIRPath "path" (e.g.
      # "Patient.name"), the property name/index it was reached through, and the raw data
      # itself.
      class ResourceNode
        attr_reader :data, :path, :prop_name, :index

        def initialize(data, path, prop_name: nil, index: nil)
          path = data["resourceType"] if data.is_a?(::Hash) && data.key?("resourceType")

          @data = data
          @path = path
          @prop_name = prop_name
          @index = index
        end

        def ==(other)
          data == (other.is_a?(ResourceNode) ? other.data : other)
        end

        # No model-aware typing (used by `is`/`as`) yet, so this always resolves via the raw
        # data's Ruby class rather than a FHIR model's type hierarchy.
        def type_info
          return nil if path.nil?

          match = path.match(/\ASystem\.(.*)\z/)
          return TypeInfo.new(match[1], TypeInfo::SYSTEM) if match
          return TypeInfo.new(path, TypeInfo::FHIR) unless path.include?(".")

          TypeInfo.create_by_value_in_namespace(TypeInfo::FHIR, data)
        end

        # A UCUM-coded quantity-shaped object (e.g. a FHIR Quantity/Duration/Age element:
        # {"value" => ..., "unit" => ..., "system" => "http://unitsofmeasure.org", "code" => ...})
        # resolves to an FPQuantity built from its "code", not its (human-readable) "unit".
        def convert_data
          return data unless data.is_a?(::Hash) && data["system"] == "http://unitsofmeasure.org"

          code = data["code"]
          unit = FPQuantity::TIME_UNITS_TO_UCUM[code] || "'#{code}'"
          FPQuantity.new(data["value"], unit)
        end

        def self.create_node(data, path = nil, prop_name: nil, index: nil)
          return data if data.is_a?(ResourceNode)

          new(data, path, prop_name: prop_name, index: index)
        end
      end
    end
  end
end
