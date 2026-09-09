# frozen_string_literal: true

require "grape"

module FhirpathServer
  # fhirpath-py-server's aiohttp handler parses the request body as JSON regardless of
  # Content-Type. Grape's formatter middleware, by contrast, 415s a body whose Content-Type
  # isn't one of its registered input mime types, and only one mime type can be registered per
  # format (a later `content_type :json, ...` call replaces the earlier one rather than adding
  # an alias) - so a FHIR-flavored "application/fhir+json" Content-Type is normalized to
  # "application/json" here, ahead of Grape's own format detection.
  class NormalizeFhirJsonContentType
    FHIR_JSON = %r{\Aapplication/fhir\+json}i

    def initialize(app)
      @app = app
    end

    def call(env)
      env["CONTENT_TYPE"] = "application/json" if FHIR_JSON.match?(env["CONTENT_TYPE"].to_s)
      @app.call(env)
    end
  end

  # Implements https://github.com/brianpos/fhirpath-lab/blob/develop/server-api.md: a POST
  # endpoint per FHIR version that takes a Parameters resource (expression, resource, context,
  # variables, terminologyserver) and returns the evaluation as a Parameters resource. Ruby port
  # of fhirpath-py-server's main.py + fhirpath.py request handlers.
  class API < Grape::API
    use NormalizeFhirJsonContentType

    format :json

    rescue_from Fhirpath::Error do |error|
      error!(operation_outcome("invalid", "Invalid input: #{error.message}"), 400)
    end

    rescue_from :all do |error|
      error!(operation_outcome("exception", "Internal server error: #{error.message}"), 500)
    end

    helpers do
      def operation_outcome(code, text)
        {
          "resourceType" => "OperationOutcome",
          "issue" => [{ "severity" => "error", "code" => code, "details" => { "text" => text } }]
        }
      end

      def evaluate_fhirpath(model)
        parsed = RequestParser.call(params.to_h)
        error!({ "error" => "Not enough data" }, 400) if parsed.expression.nil? || parsed.resource.nil?

        variables = parsed.variables.merge("resource" => parsed.resource)

        status 200
        {
          "resourceType" => "Parameters",
          "id" => "fhirpath",
          "parameter" => ResponseBuilder.call(model:, parsed:, variables:)
        }
      end
    end

    resource :fhir do
      desc "Evaluate a FHIRPath expression against an R4 resource"
      post "$fhirpath" do
        evaluate_fhirpath("r4")
      end

      desc "Evaluate a FHIRPath expression against an R5 resource"
      post "$fhirpath-r5" do
        evaluate_fhirpath("r5")
      end
    end
  end
end
