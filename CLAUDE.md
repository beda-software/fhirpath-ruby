# fhirpath-rb

Ruby implementation of [FHIRPath](https://hl7.org/fhirpath/), the expression language used to
navigate and extract data from FHIR resources. This is a **port of
[fhirpath-py](https://github.com/beda-software/fhirpath-py)** — when in doubt about behavior,
naming, or edge cases, treat fhirpath-py as the reference implementation rather than
re-deriving from the spec alone. fhirpath-py is itself a port of
[fhirpath.js](https://github.com/HL7/fhirpath.js) (the canonical HL7 reference implementation),
so fhirpath.js is the next place to check if fhirpath-py is ambiguous.

## Status

Repo scaffolding only — no evaluator code has been ported yet. `lib/fhirpath.rb` just defines
the `Fhirpath` module and `Fhirpath::Error`. Everything in "Planned architecture" below
describes the target design, not current code.

## Planned architecture

Mirror fhirpath-py's module boundaries; they map cleanly to a Ruby gem's `lib/` layout:

| fhirpath-py | Planned Ruby equivalent | Purpose |
|---|---|---|
| `fhirpathpy/__init__.py` (`evaluate`, `compile`) | `lib/fhirpath.rb` (`Fhirpath.evaluate`, `Fhirpath.compile`) | Public API |
| `fhirpathpy/parser/FHIRPath.g4` + antlr-generated parser | `lib/fhirpath/parser/` | Grammar + parser producing an AST. No Ruby ANTLR runtime is planned by default — evaluate whether to generate a parser from the same `.g4` grammar (via a build step, not committed generated code) or hand-write a recursive-descent/Parslet/Racc parser that accepts the same grammar. |
| `fhirpathpy/engine/nodes.py` (`FP_Type`, `FP_Quantity`, `FP_DateTime`, `ResourceNode`, ...) | `lib/fhirpath/engine/nodes.rb` (or one file per type under `lib/fhirpath/engine/nodes/`) | FHIRPath value types (quantities, date/time with partial precision, resource wrapper) and their `equals`/`equivalent_to`/`compare` semantics |
| `fhirpathpy/engine/__init__.py` (`do_eval`) + `evaluators/` | `lib/fhirpath/engine/evaluator.rb` | AST node dispatch — walks the parsed tree and evaluates each node kind against the current context |
| `fhirpathpy/engine/invocations/*.py` (aggregate, collections, combining, constants, datetime, equality, existence, filtering, logic, math, misc, navigation, strings, subsetting, types) | `lib/fhirpath/engine/invocations/*.rb`, one file per category | Built-in function library (`where`, `select`, `first`, `substring`, `today()`, ...); each category stays its own file to match fhirpath-py |
| `fhirpathpy/engine/util.py` (`get_data`, `parse_value`, `set_paths`, `arraify`, `process_user_invocation_table`) | `lib/fhirpath/engine/util.rb` | Shared helpers used across the engine |
| `fhirpathpy/models/{dstu2,stu3,r4,r5}` | `lib/fhirpath/models/{dstu2,stu3,r4,r5}.rb` | Per-FHIR-version model data (choice-type expansion, primitive extension handling) used to disambiguate polymorphic fields like `Patient.deceased[x]` |

Public API surface to match fhirpath-py's `evaluate`/`compile` (see its README):

```ruby
Fhirpath.evaluate(resource, path, context = {}, model = nil, options = {})
Fhirpath.compile(path, model = nil, options = {}) # => callable, parses once, reusable across resources
```

`options[:user_invocation_table]` should let callers override or add functions, mirroring
fhirpath-py's `userInvocationTable` (see its README's "User-defined functions" section).

## Test strategy

fhirpath-py's `tests/cases/*.yaml` are FHIRPath-spec-section-organized YAML test cases (e.g.
`5.1_existence.yaml`, `6.5_boolean_logic.yaml`) plus FHIR-specific cases (`fhir-r4.yaml`,
`fhir-quantity.yaml`). When porting the evaluator, port these fixtures (or write a shared
YAML-driven RSpec runner that reads an equivalent fixture format) rather than inventing a
parallel set of hand-written examples — they encode a lot of spec edge cases that are easy to
miss otherwise.

## Conventions

- Ruby >= 3.0, `frozen_string_literal: true` in every file.
- Gem name is `fhirpath-rb` (matching the `fhirpath-py` naming pattern) but the module is flat
  `Fhirpath`, not `Fhirpath::Rb` — `rb`/`py` are naming suffixes on the repo/gem, not part of
  the API, so callers write `Fhirpath.evaluate(...)`, not `Fhirpath::Rb.evaluate(...)`.
- RSpec for tests (`spec/`), RuboCop for linting (`.rubocop.yml`). `bundle exec rake` runs both
  (the default Rake task) and must stay clean.
- No implementation code should be added speculatively — this file describes the target shape
  so future work has a map, not a request to build it all now.
