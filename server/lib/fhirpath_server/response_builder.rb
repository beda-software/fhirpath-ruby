# frozen_string_literal: true

module FhirpathServer
  # Builds the fhirpath-lab response Parameters resource for one evaluation request. Ruby port
  # of fhirpath-py-server's create_parameters (fhirpath_py_server/fhirpath.py) — minus trace
  # collection, which isn't wired through fhirpath-rb's public API yet (see ResultFormatter).
  class ResponseBuilder
    def self.call(model:, parsed:, variables:)
      new(model:, parsed:, variables:).call
    end

    def initialize(model:, parsed:, variables:)
      @model = model
      @parsed = parsed
      @variables = variables
    end

    def call
      [header_parameter, *result_parameters]
    end

    private

    attr_reader :model, :parsed, :variables

    def resource
      parsed.resource
    end

    def context
      parsed.context
    end

    def result_parameters
      return [result_parameter(expression_results(resource))] unless context

      resource_type_path = resource["resourceType"] ? "#{resource["resourceType"]}." : ""

      context_nodes_data.each_with_index.map do |context_node, index|
        result_parameter(
          expression_results(context_node),
          value_string: "#{resource_type_path}#{context}[#{index}]"
        )
      end
    end

    def context_nodes_data
      Array(Fhirpath.evaluate(resource, context, variables, model))
    end

    def expression_results(data)
      ResultFormatter.call(Fhirpath.evaluate(data, parsed.expression, variables, model))
    end

    def result_parameter(parts, value_string: nil)
      { "name" => "result", "part" => parts, **(value_string ? { "valueString" => value_string } : {}) }
    end

    def header_parameter
      { "name" => "parameters", "part" => header_parts }
    end

    def header_parts
      [
        { "name" => "evaluator", "valueString" => evaluator_stamp },
        *(context ? [{ "name" => "context", "valueString" => context }] : []),
        { "name" => "expression", "valueString" => parsed.expression },
        { "name" => "resource", "resource" => resource },
        { "name" => "terminologyServerUrl", "valueString" => parsed.terminology_server },
        variables_parameter
      ]
    end

    def variables_parameter
      # "resource" is injected into `variables` below so `%resource` resolves inside the
      # expression, but it's a whole FHIR resource, not a string — already reported under its
      # own "resource" parameter above, so it's left out of this valueString-typed list.
      user_variables = variables.except("resource")
      part = user_variables.map { |key, value| { "name" => key, "valueString" => value } }
      { "name" => "variables", **(part.empty? ? {} : { "part" => part }) }
    end

    def evaluator_stamp
      suffix = model == "r5" ? "-R5" : ""
      "fhirpath-rb #{Fhirpath::VERSION}#{suffix}"
    end
  end
end
