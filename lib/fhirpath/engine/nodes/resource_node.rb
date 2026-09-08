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

        # A path with no dot is already a bare type name (e.g. "Observation", or "id" once
        # path2Type has resolved it during navigation). A dotted path with a model active means
        # this node is a nested element with no specific named type — a FHIR BackboneElement;
        # without a model, fall back to inferring the type from the raw Ruby value.
        def type_info(model)
          return nil if path.nil?

          match = path.match(/\ASystem\.(.*)\z/)
          return TypeInfo.new(match[1], TypeInfo::SYSTEM) if match
          return TypeInfo.new(path, TypeInfo::FHIR) unless path.include?(".")
          return TypeInfo.new("BackboneElement", TypeInfo::FHIR) if model

          TypeInfo.create_by_value_in_namespace(TypeInfo::FHIR, data)
        end

        # A UCUM-coded quantity-shaped object (e.g. a FHIR Quantity/Duration/Age element:
        # {"value" => ..., "unit" => ..., "system" => "http://unitsofmeasure.org", "code" => ...})
        # resolves to an FPQuantity built from its "code", not its (human-readable) "unit". A
        # present "comparator" (e.g. ">5 mg") makes the value an inexact bound, not a precise
        # quantity — System.Quantity has no comparator concept, so it can't be converted.
        def convert_data
          return data unless data.is_a?(::Hash) && data["system"] == "http://unitsofmeasure.org"

          if data.key?("comparator")
            raise Fhirpath::Error, "Cannot convert a Quantity with a comparator to System.Quantity"
          end

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
