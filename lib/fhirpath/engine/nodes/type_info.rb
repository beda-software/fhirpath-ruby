# frozen_string_literal: true

require "bigdecimal"

module Fhirpath
  module Engine
    module Nodes
      # Ruby port of fhirpath-py's TypeInfo (fhirpathpy/engine/nodes.py), used by `ofType`.
      # Model-aware type hierarchy resolution (`TypeInfo.model`, used by `is`/`as`) isn't ported
      # yet — only the model-less path needed by `ofType` without a model.
      class TypeInfo
        SYSTEM = "System"
        FHIR = "FHIR"

        attr_reader :name, :namespace

        def initialize(name, namespace)
          @name = name
          @namespace = namespace
        end

        def is_(other)
          return false unless other.is_a?(TypeInfo)
          return false unless namespace.nil? || other.namespace.nil? || namespace == other.namespace

          name == other.name
        end

        def self.from_value(value)
          return value.type_info if value.is_a?(ResourceNode)

          create_by_value_in_namespace(SYSTEM, value)
        end

        def self.create_by_value_in_namespace(namespace, value)
          name = type_name_for(value)
          name = namespace == SYSTEM ? name.capitalize : name
          new(name, namespace)
        end

        TYPE_NAMES_BY_CLASS = {
          ::Integer => "integer",
          ::Float => "decimal",
          ::BigDecimal => "decimal",
          FPDateTime => "dateTime",
          FPQuantity => "Quantity",
          ::String => "string",
          ::Hash => "object"
        }.freeze

        def self.type_name_for(value)
          return "boolean" if [true, false].include?(value)

          matched = TYPE_NAMES_BY_CLASS.find { |klass, _name| value.is_a?(klass) }
          matched ? matched.last : value.class.name
        end
      end
    end
  end
end
