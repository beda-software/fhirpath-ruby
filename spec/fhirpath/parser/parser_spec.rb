# frozen_string_literal: true

require "json"

RSpec.describe Fhirpath::Parser do
  def load_ast_fixture(expression)
    path = File.join(__dir__, "fixtures", "ast", "#{expression}.json")
    JSON.parse(File.read(path))
  end

  describe ".parse" do
    %w[
      4+4
      object
      object.method()
      object.method(42)
      object.property
      object.property.method()
      object.property.method(42)
    ].each do |expression|
      it "parses #{expression.inspect} without raising" do
        expect(described_class.parse(expression)).not_to eq({})
      end
    end

    [
      "!",
      "(",
      "a.",
      "1 +",
      "a..b",
      "'unterminated"
    ].each do |expression|
      it "raises Fhirpath::Error for invalid input #{expression.inspect}" do
        expect { described_class.parse(expression) }
          .to raise_error(Fhirpath::Error, "Failed to parse #{expression.inspect}")
      end
    end

    %w[
      %v+2
      a.b+2
      Observation.value
      Patient.name.given
    ].each do |expression|
      it "builds the expected AST for #{expression.inspect}" do
        expect(described_class.parse(expression)).to eq(load_ast_fixture(expression))
      end
    end
  end
end
