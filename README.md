# fhirpath-rb

[FHIRPath](https://hl7.org/fhirpath/) implementation in Ruby.

This is a Ruby port of [fhirpath-py](https://github.com/beda-software/fhirpath-py), which is
itself a Python port of [fhirpath.js](https://github.com/HL7/fhirpath.js). The goal is to bring
the same evaluator (parser, engine, built-in function library, and FHIR data models) to the
Ruby ecosystem.

## Installation

Not yet released to RubyGems. Once published:

```bash
bundle add fhirpath-rb
```

## Planned usage

```ruby
require "fhirpath"

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
