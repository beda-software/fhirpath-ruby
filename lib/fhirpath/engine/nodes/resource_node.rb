# frozen_string_literal: true

module Fhirpath
  module Engine
    module Nodes
      # Ruby port of fhirpath-py's ResourceNode (fhirpathpy/engine/nodes.py): wraps a node of
      # data reached while navigating a resource, tracking its FHIRPath "path" (e.g.
      # "Patient.name"), the property name/index it was reached through, and the raw data
      # itself. Only what path navigation needs so far; get_type_info/convert_data (used by
      # `is`/`as`/`ofType` and by primitive Quantity data) aren't ported yet.
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

        def self.create_node(data, path = nil, prop_name: nil, index: nil)
          return data if data.is_a?(ResourceNode)

          new(data, path, prop_name: prop_name, index: index)
        end
      end
    end
  end
end
