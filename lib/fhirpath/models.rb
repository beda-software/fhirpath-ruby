# frozen_string_literal: true

require "json"

module Fhirpath
  # Ruby port of fhirpath-py's fhirpathpy/models/__init__.py: loads the per-FHIR-version model
  # data (choice-type expansion, path-to-type mapping, ...) used to disambiguate polymorphic
  # fields like `Patient.deceased[x]`. Each subdirectory here (r4, r5, stu3, dstu2) holds the
  # JSON files copied verbatim from fhirpath-py's model data for that version.
  module Models
    DIR = File.join(__dir__, "models")

    REGISTRY = Dir.children(DIR).sort.each_with_object({}) do |version, models|
      next unless File.directory?(File.join(DIR, version))

      models[version] = Dir.glob(File.join(DIR, version, "*.json")).each_with_object({}) do |path, data|
        data[File.basename(path, ".json")] = JSON.parse(File.read(path))
      end
    end.freeze

    def self.[](name)
      REGISTRY[name]
    end
  end
end
