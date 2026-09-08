# frozen_string_literal: true

require_relative "invocations/navigation"
require_relative "invocations/filtering"
require_relative "invocations/equality"
require_relative "invocations/existence"
require_relative "invocations/combining"
require_relative "invocations/math"
require_relative "invocations/subsetting"
require_relative "invocations/misc"
require_relative "invocations/strings"
require_relative "invocations/datetime"
require_relative "invocations/types"

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of the base `invocation_registry` built in fhirpath-py's
      # fhirpathpy/engine/invocations/__init__.py. Only entries needed so far are ported; see
      # the category modules required above.
      REGISTRY = {
        "where" => { fn: Filtering.method(:where), arity: { 1 => ["Expr"] } },
        "select" => { fn: Filtering.method(:select), arity: { 1 => ["Expr"] } },
        "repeat" => { fn: Filtering.method(:repeat), arity: { 1 => ["Expr"] } },
        "ofType" => { fn: Filtering.method(:of_type), arity: { 1 => ["TypeSpecifier"] } },
        "extension" => { fn: Filtering.method(:extension), arity: { 1 => ["String"] } },
        "is" => { fn: Types.method(:is), arity: { 1 => ["TypeSpecifier"] } },
        "as" => { fn: Types.method(:as), arity: { 1 => ["TypeSpecifier"] } },
        "isOp" => { fn: Types.method(:is), arity: { 2 => %w[Any TypeSpecifier] } },
        "asOp" => { fn: Types.method(:as), arity: { 2 => %w[Any TypeSpecifier] } },
        "single" => { fn: Filtering.method(:single) },
        "first" => { fn: Filtering.method(:first) },
        "last" => { fn: Filtering.method(:last) },
        "tail" => { fn: Filtering.method(:tail) },
        "take" => { fn: Filtering.method(:take), arity: { 1 => ["Integer"] } },
        "skip" => { fn: Filtering.method(:skip), arity: { 1 => ["Integer"] } },
        "children" => { fn: Navigation.method(:children) },
        "descendants" => { fn: Navigation.method(:descendants) },
        "combine" => { fn: Combining.method(:combine), arity: { 1 => ["AnyAtRoot"] } },
        "coalesce" => { fn: Combining.method(:coalesce), variadic: "Expr" },
        "|" => { fn: Combining.method(:union), arity: { 2 => %w[Any Any] } },
        "intersect" => { fn: Subsetting.method(:intersect), arity: { 1 => ["AnyAtRoot"] } },
        "empty" => { fn: Existence.method(:empty) },
        "not" => { fn: Existence.method(:not) },
        "exists" => { fn: Existence.method(:exists), arity: { 0 => [], 1 => ["Expr"] } },
        "all" => { fn: Existence.method(:all), arity: { 1 => ["Expr"] } },
        "allTrue" => { fn: Existence.method(:all_true) },
        "anyTrue" => { fn: Existence.method(:any_true) },
        "allFalse" => { fn: Existence.method(:all_false) },
        "anyFalse" => { fn: Existence.method(:any_false) },
        "subsetOf" => { fn: Existence.method(:subset_of), arity: { 1 => ["AnyAtRoot"] } },
        "supersetOf" => { fn: Existence.method(:superset_of), arity: { 1 => ["AnyAtRoot"] } },
        "isDistinct" => { fn: Existence.method(:distinct?) },
        "distinct" => { fn: Existence.method(:distinct) },
        "count" => { fn: Existence.method(:count) },
        "=" => { fn: Equality.method(:equal), arity: { 2 => %w[Any Any] }, nullable: true },
        "!=" => { fn: Equality.method(:unequal), arity: { 2 => %w[Any Any] }, nullable: true },
        "~" => { fn: Equality.method(:equival), arity: { 2 => %w[Any Any] } },
        "!~" => { fn: Equality.method(:unequival), arity: { 2 => %w[Any Any] } },
        "<" => { fn: Equality.method(:lt), arity: { 2 => %w[Any Any] }, nullable: true },
        ">" => { fn: Equality.method(:gt), arity: { 2 => %w[Any Any] }, nullable: true },
        "<=" => { fn: Equality.method(:lte), arity: { 2 => %w[Any Any] }, nullable: true },
        ">=" => { fn: Equality.method(:gte), arity: { 2 => %w[Any Any] }, nullable: true },
        "+" => { fn: Math.method(:plus), arity: { 2 => %w[Any Any] }, nullable: true },
        "iif" => { fn: Misc.method(:iif), arity: { 2 => %w[Expr Expr], 3 => %w[Expr Expr Expr] } },
        "trace" => { fn: Misc.method(:trace), arity: { 0 => [], 1 => ["String"] } },
        "toInteger" => { fn: Misc.method(:to_integer) },
        "toDecimal" => { fn: Misc.method(:to_decimal) },
        "toString" => { fn: Misc.method(:to_string) },
        "toDate" => { fn: Misc.method(:to_date) },
        "toDateTime" => { fn: Misc.method(:to_date_time) },
        "toTime" => { fn: Misc.method(:to_time) },
        "toQuantity" => { fn: Misc.method(:to_quantity), arity: { 0 => [], 1 => ["String"] } },
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
        "truncate" => { fn: Math.method(:truncate) },
        "now" => { fn: Datetime.method(:now) },
        "today" => { fn: Datetime.method(:today) },
        "timeOfDay" => { fn: Datetime.method(:time_of_day) }
      }.freeze
    end
  end
end
