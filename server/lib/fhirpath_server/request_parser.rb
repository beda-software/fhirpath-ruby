# frozen_string_literal: true

module FhirpathServer
  # Reads the fhirpath-lab request shape (a FHIR Parameters resource with "expression",
  # "resource", "context", "variables" and "terminologyserver" parameters) into plain values.
  # Ruby port of fhirpath-py-server's parse_request_data (fhirpath_py_server/fhirpath.py).
  class RequestParser
    Result = Struct.new(
      :expression, :resource, :context, :terminology_server, :variables, :validate, keyword_init: true
    )

    def self.call(body)
      new(body).call
    end

    def initialize(body)
      @parameters = Array(body["parameter"])
    end

    def call
      result = Result.new(variables: {})

      parameters.each do |param|
        apply_parameter(result, param)
      end

      result
    end

    private

    attr_reader :parameters

    def apply_parameter(result, param)
      case param["name"]
      when "expression" then result.expression = param["valueString"]
      when "resource" then result.resource = param["resource"]
      when "context" then result.context = param["valueString"]
      when "validate" then result.validate = param["valueBoolean"]
      when "variables" then result.variables = variables_from(param)
      when "terminologyserver" then result.terminology_server = param["valueString"]
      end
    end

    def variables_from(param)
      Array(param["part"]).to_h { |part| [part["name"], part["valueString"]] }
    end
  end
end
