# frozen_string_literal: true

module Fhirpath
  module Engine
    module Invocations
      # The string functions and single-argument math functions half of REGISTRY (see
      # invocations.rb, which merges this in) — split out purely to keep that module's line
      # count down.
      REGISTRY_STRINGS_AND_MATH = {
        "indexOf" => { fn: Strings.method(:index_of), arity: { 1 => ["String"] }, nullable_input: true },
        "substring" => {
          fn: Strings.method(:substring),
          arity: { 1 => ["Integer"], 2 => %w[Integer Integer] },
          nullable_input: true
        },
        "startsWith" => { fn: Strings.method(:starts_with), arity: { 1 => ["String"] }, nullable_input: true },
        "endsWith" => { fn: Strings.method(:ends_with), arity: { 1 => ["String"] }, nullable_input: true },
        "contains" => { fn: Strings.method(:contains), arity: { 1 => ["String"] }, nullable_input: true },
        "upper" => { fn: Strings.method(:upper), nullable_input: true },
        "lower" => { fn: Strings.method(:lower), nullable_input: true },
        "replace" => { fn: Strings.method(:replace), arity: { 2 => %w[String String] }, nullable_input: true },
        "matches" => { fn: Strings.method(:matches), arity: { 1 => ["String"] }, nullable_input: true },
        "replaceMatches" => {
          fn: Strings.method(:replace_matches),
          arity: { 2 => %w[String String] },
          nullable_input: true
        },
        "length" => { fn: Strings.method(:length), nullable_input: true },
        "toChars" => { fn: Strings.method(:to_chars) },
        "join" => { fn: Strings.method(:join), arity: { 0 => [], 1 => ["String"] } },
        "split" => { fn: Strings.method(:split), arity: { 1 => ["String"] }, nullable_input: true },
        "trim" => { fn: Strings.method(:trim), nullable_input: true },
        "encode" => { fn: Strings.method(:encode), arity: { 1 => ["String"] } },
        "decode" => { fn: Strings.method(:decode), arity: { 1 => ["String"] } },
        "abs" => { fn: Math.method(:abs) },
        "ceiling" => { fn: Math.method(:ceiling) },
        "exp" => { fn: Math.method(:exp) },
        "floor" => { fn: Math.method(:floor) },
        "ln" => { fn: Math.method(:ln) },
        "log" => { fn: Math.method(:log), arity: { 1 => ["Number"] }, nullable: true },
        "power" => { fn: Math.method(:power), arity: { 1 => ["Number"] }, nullable: true },
        "round" => { fn: Math.method(:round), arity: { 1 => ["Number"] } },
        "sqrt" => { fn: Math.method(:sqrt) },
        "truncate" => { fn: Math.method(:truncate) }
      }.freeze
    end
  end
end
