# frozen_string_literal: true

require "spec_helper"
require "json"

RSpec.describe FhirpathServer::API do
  def app
    described_class
  end

  def post_fhirpath(path, body)
    post path, JSON.generate(body), "CONTENT_TYPE" => "application/json"
    JSON.parse(last_response.body)
  end

  let(:patient) do
    {
      "resourceType" => "Patient",
      "id" => "example",
      "active" => true,
      "name" => [{ "family" => "Chalmers", "given" => %w[Peter James] }]
    }
  end

  it "evaluates an expression against an R4 resource" do
    body = post_fhirpath(
      "/fhir/$fhirpath",
      "resourceType" => "Parameters",
      "parameter" => [
        { "name" => "expression", "valueString" => "name.given" },
        { "name" => "resource", "resource" => patient }
      ]
    )

    expect(last_response.status).to eq(200)
    expect(body["resourceType"]).to eq("Parameters")

    result_part = body["parameter"].find { |p| p["name"] == "result" }
    values = result_part["part"].map { |p| p["valueString"] }
    expect(values).to eq(%w[Peter James])
  end

  it "evaluates per context node when a context expression is given" do
    body = post_fhirpath(
      "/fhir/$fhirpath",
      "resourceType" => "Parameters",
      "parameter" => [
        { "name" => "expression", "valueString" => "given" },
        { "name" => "context", "valueString" => "name" },
        { "name" => "resource", "resource" => patient }
      ]
    )

    result_parts = body["parameter"].select { |p| p["name"] == "result" }
    expect(result_parts.length).to eq(1)
    expect(result_parts.first["valueString"]).to eq("Patient.name[0]")
  end

  it "resolves variables passed alongside the expression" do
    body = post_fhirpath(
      "/fhir/$fhirpath",
      "resourceType" => "Parameters",
      "parameter" => [
        { "name" => "expression", "valueString" => "%who" },
        { "name" => "resource", "resource" => patient },
        {
          "name" => "variables",
          "part" => [{ "name" => "who", "valueString" => "Peter" }]
        }
      ]
    )

    result_part = body["parameter"].find { |p| p["name"] == "result" }
    expect(result_part["part"].first["valueString"]).to eq("Peter")
  end

  it "maps booleans, integers and quantities to their typed value fields" do
    body = post_fhirpath(
      "/fhir/$fhirpath",
      "resourceType" => "Parameters",
      "parameter" => [
        { "name" => "expression", "valueString" => "active" },
        { "name" => "resource", "resource" => patient }
      ]
    )

    result_part = body["parameter"].find { |p| p["name"] == "result" }
    expect(result_part["part"]).to eq([{ "name" => "boolean", "valueBoolean" => true }])
  end

  it "returns 400 with an error body when expression or resource is missing" do
    body = post_fhirpath(
      "/fhir/$fhirpath",
      "resourceType" => "Parameters",
      "parameter" => [{ "name" => "expression", "valueString" => "name.given" }]
    )

    expect(last_response.status).to eq(400)
    expect(body).to eq("error" => "Not enough data")
  end

  it "returns an OperationOutcome for an invalid FHIRPath expression" do
    body = post_fhirpath(
      "/fhir/$fhirpath",
      "resourceType" => "Parameters",
      "parameter" => [
        { "name" => "expression", "valueString" => "name.(((" },
        { "name" => "resource", "resource" => patient }
      ]
    )

    expect(last_response.status).to eq(400)
    expect(body["resourceType"]).to eq("OperationOutcome")
  end

  it "evaluates against the R5 route with the R5 model" do
    body = post_fhirpath(
      "/fhir/$fhirpath-r5",
      "resourceType" => "Parameters",
      "parameter" => [
        { "name" => "expression", "valueString" => "evaluator" },
        { "name" => "resource", "resource" => patient }
      ]
    )

    header = body["parameter"].find { |p| p["name"] == "parameters" }
    evaluator = header["part"].find { |p| p["name"] == "evaluator" }
    expect(evaluator["valueString"]).to end_with("-R5")
  end
end
