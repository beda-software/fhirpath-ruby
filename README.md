# fhirpath-rb

[FHIRPath](https://hl7.org/fhirpath/) implementation in Ruby.

This is a Ruby port of [fhirpath-py](https://github.com/beda-software/fhirpath-py), which is
itself a Python port of [fhirpath.js](https://github.com/HL7/fhirpath.js). The goal is to bring
the same evaluator (parser, engine, built-in function library, and FHIR data models) to the
Ruby ecosystem.

## Installation

```bash
bundle add fhirpath-rb
```

## Usage

`compile_as_first` and `compile_as_array` parse a FHIRPath expression once and return a
reusable callable that accepts a [fhir_models](https://github.com/fhir-crucible/fhir_models)
resource instance and wraps results as instances of a given `output_type` (raw values pass
through as-is when `output_type` isn't a fhir_models class):

```ruby
require "fhirpath"

patient = FHIR::Patient.new(
  "name" => [
    { "use" => "official", "given" => ["Peter", "James"], "family" => "Chalmers" },
    { "use" => "usual", "given" => ["Jim"] }
  ]
)

first_name = Fhirpath.compile_as_first("Patient.name.where(use = 'usual')", FHIR::Patient, FHIR::HumanName)
first_name.call(patient)
# => #<FHIR::HumanName ...>

all_given = Fhirpath.compile_as_array("Patient.name.given", FHIR::Patient, String)
all_given.call(patient)
# => ["Peter", "James", "Jim"]
```

`Fhirpath.evaluate` works directly against a plain resource Hash and returns raw values:

```ruby
patient = {
  "resourceType" => "Patient",
  "name" => [
    { "use" => "official", "given" => ["Peter", "James"], "family" => "Chalmers" },
    { "use" => "usual", "given" => ["Jim"] }
  ]
}

Fhirpath.evaluate(patient, "Patient.name.where(use = 'usual').given.first()")
# => ["Jim"]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then run `rake spec` to
run the tests, and `bundle exec rake` to run the full default task (specs + rubocop). You can
also run `bin/console` for an interactive prompt.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).
