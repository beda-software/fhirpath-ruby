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

## Release process ("bump")

The maintainer typing **"bump"** (or "bump X.Y.Z") to Claude is standing, in-the-moment
authorization for the full state-changing sequence below — commit, push, tag, push tag, and
GitHub release — for that one release only. No separate confirmation is needed per step; run
the whole sequence end-to-end without pausing to ask "should I push now?" etc.

**Version to release:**
- Plain **"bump"** → increment the patch version (Z in X.Y.Z) of whatever's currently in
  `lib/fhirpath/version.rb`.
- **"bump X.Y.Z"** (an explicit version, e.g. for a minor/major bump like `0.2.0`) → set the
  version to exactly that string instead of incrementing.

**Steps, in order:**
1. `git status` — working tree must be clean and up to date with `origin/main` before starting.
   If it isn't (uncommitted changes, unrelated local commits), stop and ask rather than
   assuming they should be swept into the release.
2. Edit `lib/fhirpath/version.rb` to the new version.
3. Run `bundle exec rake` (specs + RuboCop) and confirm it's green. If parser sources aren't
   already built, run `bundle exec rake parser:setup compile` first (see rakelib/parser.rake).
4. **Mandatory packaging sanity check** — this is the step that was skipped before 0.1.1/0.1.2
   shipped a broken native extension (the gemspec's generated-files glob had silently gone
   missing and nothing caught it until a user hit a `LoadError` in production):
   - `gem build fhirpath-rb.gemspec`
   - Install the built `.gem` into a throwaway isolated `GEM_HOME` (e.g. under a scratch dir),
     with `env -u BUNDLE_GEMFILE -u RUBYOPT` to avoid this repo's own bundler env leaking in,
     and with `GEM_PATH` pointing at a location that already has `rice`/`fhir_models` installed
     (or allow network) so dependencies resolve.
   - From that isolated `GEM_HOME`, `require "fhirpath"` and call `Fhirpath.evaluate` on a
     trivial resource. Confirm the native extension (`fhir_path_parser.bundle`/`.so`) actually
     got compiled into that GEM_HOME's `extensions/` dir and the require succeeds.
   - Clean up the scratch gem/dirs afterward. If this check fails, stop — do not tag or release
     a broken build; fix the gemspec/extension setup first.
5. `git add lib/fhirpath/version.rb` (plus any other files that were part of this bump, e.g. a
   packaging fix) and commit as `Bump X.Y.Z`, with whatever commit attribution footer is
   currently in effect for the session.
6. `git push origin main`.
7. `git tag -a vX.Y.Z -m "Version X.Y.Z"` and `git push origin vX.Y.Z`.
8. `gh release create vX.Y.Z --title "vX.Y.Z" --generate-notes` — this triggers
   `.github/workflows/release.yml`, which publishes to rubygems.org via Trusted Publishing.
9. `gh run watch <run-id> --exit-status` (find the run with `gh run list --workflow=release.yml
   --limit 1`) and confirm it completes successfully.
10. Final live-artifact check: in a scratch dir, `gem install fhirpath-rb -v X.Y.Z` from
    rubygems.org (not the local build) and `require "fhirpath"` to confirm what's actually
    published works, not just what was built locally.
11. Report back: new version, release URL, and confirmation that the published gem loads.

If step 4 or 10 fails, the release is broken in the same way 0.1.1/0.1.2 were — do not consider
the release done, and do not stop at "gem pushed successfully" as the definition of success.
`gem push` succeeding only means RubyGems accepted the upload; it says nothing about whether
the native extension actually compiles for an installer.
