# frozen_string_literal: true

require "yaml"
require "json"
require "date"

# Runs the FHIRPath spec cases ported from fhirpath-py's tests/cases/*.yaml
# (https://github.com/beda-software/fhirpath-py/tree/master/tests/cases),
# mirroring the collection logic in its tests/conftest.py.
module DataFileTestSupport
  FIXTURES_DIR = File.join(__dir__, "fixtures")

  RESOURCES = Dir.glob(File.join(FIXTURES_DIR, "resources/*.json")).each_with_object({}) do |path, hash|
    hash[File.basename(path)] = JSON.parse(File.read(path))
  end

  def self.each_case(suites, ancestor_disabled: false, &block)
    suites.each { |suite| visit_suite(suite, ancestor_disabled, &block) }
  end

  def self.visit_suite(suite, ancestor_disabled, &block)
    return unless suite.is_a?(Hash)

    disabled = ancestor_disabled || suite["disable"] == true
    group_key = suite.keys.find { |key| key.start_with?("group") }

    if group_key
      each_case(suite[group_key], ancestor_disabled: disabled, &block)
    elsif suite.key?("expression") && !disabled
      block.call(suite)
    end
  end

  def self.resource_for(test_case, default_resource)
    inputfile = test_case["inputfile"]
    return default_resource unless inputfile && RESOURCES.key?(inputfile)

    RESOURCES[inputfile]
  end

  def self.variables_for(test_case, resource)
    variables = { "resource" => resource }
    variables["context"] = Fhirpath.evaluate(resource, test_case["context"]).first if test_case["context"]
    variables.merge!(test_case["variables"]) if test_case["variables"]
    variables
  end

  def self.matches?(actual, expected)
    return true if actual == expected
    return false unless singleton_arrays?(actual, expected)

    normalized_expected = normalize_expected(expected[0])
    actual[0] == normalized_expected || actual[0].to_s == normalized_expected.to_s
  end

  def self.singleton_arrays?(actual, expected)
    actual.is_a?(Array) && expected.is_a?(Array) && actual.length == 1 && expected.length == 1
  end

  def self.normalize_expected(expected_value)
    expected_value.is_a?(String) ? Fhirpath.evaluate({}, expected_value).first : expected_value
  end
end

Dir.glob(File.join(DataFileTestSupport::FIXTURES_DIR, "cases/*.yaml")).sort.each do |path|
  data = YAML.safe_load_file(path, permitted_classes: [Date, Time, Symbol], aliases: true)
  next unless data.is_a?(Hash) && data["tests"]

  default_resource = data["subject"]

  RSpec.describe File.basename(path) do
    DataFileTestSupport.each_case(data["tests"]) do |test_case|
      resource = DataFileTestSupport.resource_for(test_case, default_resource)
      expressions = test_case["expression"].is_a?(Array) ? test_case["expression"] : [test_case["expression"]]

      expressions.each do |expression|
        it(test_case["desc"] || expression.inspect) do
          variables = DataFileTestSupport.variables_for(test_case, resource)
          model = test_case["model"]

          if test_case["error"] == true
            expect { Fhirpath.evaluate(resource, expression, variables, model) }.to raise_error(StandardError)
          else
            result = Fhirpath.evaluate(resource, expression, variables, model)
            expect(DataFileTestSupport.matches?(result, test_case["result"])).to(
              be(true), "expected #{result.inspect} to match #{test_case["result"].inspect}"
            )
          end
        end
      end
    end
  end
end
