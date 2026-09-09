# frozen_string_literal: true

require "bigdecimal"
require "json"

module FhirpathServer
  # Converts the plain Ruby values returned by Fhirpath.evaluate into the
  # {"name" => ..., "valueXxx" => ...} parts fhirpath-lab expects. Ruby port of fhirpath-py-
  # server's node_results_to_types (fhirpath_py_server/fhirpath.py).
  #
  # fhirpath-py-server distinguishes FHIR value types (e.g. "valueHumanName" vs "valueCoding")
  # by reading path/type info off its engine's ResourceNode results. Fhirpath.evaluate unwraps
  # ResourceNode down to plain Hash/Array/scalar data before returning, so that per-path type
  # info isn't available here yet; complex (Hash) results are reported generically as "object"
  # with their raw JSON attached via the fhirpath-lab json-value extension instead of the
  # specific FHIR type name. Scalars that carry their own type (booleans, integers, decimals,
  # FPQuantity/FPDateTime/FPTime) are still mapped precisely.
  module ResultFormatter
    JSON_VALUE_EXTENSION_URL = "http://fhir.forms-lab.com/StructureDefinition/json-value"

    class << self
      def call(items)
        Array(items).map { |item| format_item(item) }
      end

      private

      def format_item(item)
        case item
        when Fhirpath::Engine::Nodes::FPQuantity then quantity(item)
        when Fhirpath::Engine::Nodes::FPDateTime then { "name" => "DateTime", "valueDateTime" => item.to_s }
        when Fhirpath::Engine::Nodes::FPTime then { "name" => "Time", "valueTime" => item.to_s }
        when true, false then { "name" => "boolean", "valueBoolean" => item }
        when Integer then { "name" => "Integer", "valueInteger" => item }
        when BigDecimal, Float then { "name" => "Decimal", "valueDecimal" => item.to_f }
        when String then { "name" => "string", "valueString" => item }
        when Hash then object(item)
        else { "name" => item.class.name, "valueString" => item.to_s }
        end
      end

      def quantity(item)
        {
          "name" => "Quantity",
          "valueQuantity" => { "value" => item.value.to_f, "unit" => item.unit }
        }
      end

      def object(item)
        {
          "name" => "object",
          "extension" => [
            { "url" => JSON_VALUE_EXTENSION_URL, "valueString" => JSON.generate(item) }
          ]
        }
      end
    end
  end
end
