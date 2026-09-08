# frozen_string_literal: true

RSpec.describe Fhirpath do
  it "has a version number" do
    expect(Fhirpath::VERSION).not_to be nil
  end

  let(:patient) do
    FHIR::Patient.new(
      "resourceType" => "Patient",
      "name" => [{ "family" => "Smith", "given" => ["Alice"] }]
    )
  end

  describe ".compile_as_array" do
    it "accepts a fhir_models input_type instance and returns fhir_models output_type instances" do
      names = Fhirpath.compile_as_array("Patient.name", FHIR::Patient, FHIR::HumanName)
      result = names.call(patient)

      expect(result).to all(be_a(FHIR::HumanName))
      expect(result.map(&:family)).to eq(["Smith"])
    end

    it "returns an empty array when nothing matches" do
      names = Fhirpath.compile_as_array("Patient.name.where(use = 'nickname')", FHIR::Patient, FHIR::HumanName)

      expect(names.call(patient)).to eq([])
    end

    it "returns raw values as-is when output_type is not a fhir_models class" do
      given_names = Fhirpath.compile_as_array("Patient.name.given", FHIR::Patient, String)

      expect(given_names.call(patient)).to eq(["Alice"])
    end

    it "raises when the resource is not an instance of input_type" do
      names = Fhirpath.compile_as_array("Patient.name", FHIR::Patient, FHIR::HumanName)

      expect { names.call(FHIR::Observation.new) }.to raise_error(Fhirpath::Error, /expected FHIR::R4::Patient/)
    end

    it "raises when a result item doesn't match output_type" do
      given_names = Fhirpath.compile_as_array("Patient.name.given", FHIR::Patient, FHIR::HumanName)

      expect { given_names.call(patient) }.to raise_error(Fhirpath::Error, /Expected result to be/)
    end

    it "accepts a plain Hash resource" do
      names = Fhirpath.compile_as_array("Patient.name", ::Hash, FHIR::HumanName)

      expect(names.call(patient.to_hash).map(&:family)).to eq(["Smith"])
    end
  end

  describe ".compile_as_first" do
    it "returns the first result as a fhir_models output_type instance" do
      first_name = Fhirpath.compile_as_first("Patient.name", FHIR::Patient, FHIR::HumanName)
      result = first_name.call(patient)

      expect(result).to be_a(FHIR::HumanName)
      expect(result.family).to eq("Smith")
    end

    it "returns nil when nothing matches" do
      first_name = Fhirpath.compile_as_first("Patient.name.where(use = 'nickname')", FHIR::Patient, FHIR::HumanName)

      expect(first_name.call(patient)).to be_nil
    end
  end
end
