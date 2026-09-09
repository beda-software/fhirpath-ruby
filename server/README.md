# fhirpath-rb server

A standalone [Grape](https://github.com/ruby-grape/grape) web server that exposes
[fhirpath-rb](https://rubygems.org/gems/fhirpath-rb) over the
[fhirpath-lab server API](https://github.com/brianpos/fhirpath-lab/blob/develop/server-api.md) —
the same contract implemented by
[fhirpath-py-server](https://github.com/beda-software/fhirpath-py-server), so this server is a
drop-in Ruby alternative for tools (e.g. the [fhirpath-lab](https://fhirpath-lab.com) web UI)
that speak that API.

This directory is **not part of the `fhirpath-rb` gem** — it's excluded from the packaged gem
(see the root `fhirpath-rb.gemspec`) and only depends on `fhirpath-rb` as a regular dependency,
installed from rubygems.org (see `Gemfile`). It's distributed as its own Docker image instead.

## Endpoints

- `POST /fhir/$fhirpath` — evaluate against R4
- `POST /fhir/$fhirpath-r5` — evaluate against R5

Both take a `Parameters` resource body with `expression`, `resource`, and optionally `context`,
`variables`, and `terminologyserver` parameters, and return a `Parameters` resource with the
evaluation result(s). See the fhirpath-lab server API doc linked above for the full shape.

## Known limitation vs. fhirpath-py-server

fhirpath-py-server distinguishes FHIR value types in its response (e.g. `valueHumanName` vs.
`valueCoding`) by reading path/type info off its engine's internal node results, and supports
collecting `trace()` output into the response. `Fhirpath.evaluate` doesn't expose either of
those yet — see `lib/fhirpath_server/result_formatter.rb` for how complex (Hash) results are
reported generically instead. Scalars that carry their own type (booleans, integers, decimals,
quantities, dates/times) are still mapped precisely.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
bundle exec rackup   # or: bundle exec puma -p 8081 config.ru
```

## Docker

```bash
docker build -t fhirpath-server .
docker run -p 8081:8081 fhirpath-server
```

Pass `--build-arg FHIRPATH_RB_VERSION=1.2.3` to pin a specific `fhirpath-rb` release instead of
whatever `Gemfile`'s `~> 0.1` constraint would otherwise resolve to; the release workflow
(`.github/workflows/server-release.yml`) does this automatically for every new gem release.
