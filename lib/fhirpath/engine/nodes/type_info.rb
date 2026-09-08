# frozen_string_literal: true

require "bigdecimal"

module Fhirpath
  module Engine
    module Nodes
      # Ruby port of fhirpath-py's TypeInfo (fhirpathpy/engine/nodes.py), used by `ofType`/`is`/
      # `as`. fhirpath-py stashes the active model on a `TypeInfo.model` class attribute (set as
      # a side effect inside is_fn/as_fn, with an acknowledged "TODO: incorrect place" — it's a
      # workaround for ResourceNode#get_type_info not otherwise having access to ctx); here the
      # model is threaded through explicitly instead, since a class-level global would make
      # model-less and model-bearing `is`/`as` calls interfere across evaluations run in the
      # same process (as this gem's own test suite does).
      class TypeInfo
        SYSTEM = "System"
        FHIR = "FHIR"

        attr_reader :name, :namespace

        def initialize(name, namespace)
          @name = name
          @namespace = namespace
        end

        def is_(other, model)
          return false unless other.is_a?(TypeInfo) && namespace_compatible?(other)
          return name == other.name unless model && (namespace.nil? || namespace == FHIR)

          self.class.subtype?(model, name, other.name)
        end

        def self.from_value(value, model)
          return value.type_info(model) if value.is_a?(ResourceNode)

          create_by_value_in_namespace(SYSTEM, value)
        end

        # Walks the model's type hierarchy (subtype -> parent, falling back to path2Type) from
        # type_name looking for super_type.
        def self.subtype?(model, type_name, super_type)
          while type_name
            return true if type_name == super_type

            type_name = model.dig("type2Parent", type_name) || model.dig("path2Type", type_name)
          end

          false
        end

        def self.create_by_value_in_namespace(namespace, value)
          name = type_name_for(value)
          name = namespace == SYSTEM ? system_name(name) : name
          new(name, namespace)
        end

        # Mirrors fhirpath-py's TypeInfo.create_by_value_in_namespace: every System-namespace
        # name is capitalized, EXCEPT "dateTime" — Ruby's (and Python's) #capitalize also
        # downcases the rest of the string, which would mangle "dateTime" into "Datetime".
        def self.system_name(name)
          return "DateTime" if name == "dateTime"

          name.capitalize
        end

        TYPE_NAMES_BY_CLASS = {
          ::Integer => "integer",
          ::Float => "decimal",
          ::BigDecimal => "decimal",
          FPDateTime => "dateTime",
          FPTime => "time",
          FPQuantity => "Quantity",
          ::String => "string",
          ::Hash => "object"
        }.freeze

        def self.type_name_for(value)
          return "boolean" if [true, false].include?(value)

          matched = TYPE_NAMES_BY_CLASS.find { |klass, _name| value.is_a?(klass) }
          matched ? matched.last : value.class.name
        end

        private

        def namespace_compatible?(other)
          namespace.nil? || other.namespace.nil? || namespace == other.namespace
        end
      end
    end
  end
end
