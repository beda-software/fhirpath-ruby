# frozen_string_literal: true

require_relative "invocations/navigation"
require_relative "invocations/filtering"
require_relative "invocations/equality"
require_relative "invocations/existence"
require_relative "invocations/combining"
require_relative "invocations/math"
require_relative "invocations/subsetting"
require_relative "invocations/misc"
require_relative "invocations/misc_converts_to"
require_relative "invocations/strings"
require_relative "invocations/datetime"
require_relative "invocations/types"
require_relative "invocations/collections"
require_relative "invocations/logic"
require_relative "invocations/aggregate"
require_relative "invocations/registry_strings_and_math"

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of the base `invocation_registry` built in fhirpath-py's
      # fhirpathpy/engine/invocations/__init__.py. Only entries needed so far are ported; see
      # the category modules required above. Split across two constants purely to keep this
      # module's line count down — REGISTRY_STRINGS_AND_MATH (the string functions and the
      # single-argument math functions) lives in registry_strings_and_math.rb, which reopens
      # this module.
      REGISTRY_CORE = {
        "where" => { fn: Filtering.method(:where), arity: { 1 => ["Expr"] } },
        "select" => { fn: Filtering.method(:select), arity: { 1 => ["Expr"] } },
        "repeat" => { fn: Filtering.method(:repeat), arity: { 1 => ["Expr"] } },
        "ofType" => { fn: Filtering.method(:of_type), arity: { 1 => ["TypeSpecifier"] } },
        "extension" => { fn: Filtering.method(:extension), arity: { 1 => ["String"] } },
        "type" => { fn: Types.method(:type) },
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
        "union" => { fn: Combining.method(:union), arity: { 1 => ["AnyAtRoot"] } },
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
        "containsOp" => { fn: Collections.method(:contains), arity: { 2 => %w[Any Any] } },
        "inOp" => { fn: Collections.method(:in), arity: { 2 => %w[Any Any] } },
        "or" => { fn: Logic.method(:or_op), arity: { 2 => %w[Boolean Boolean] } },
        "and" => { fn: Logic.method(:and_op), arity: { 2 => %w[Boolean Boolean] } },
        "xor" => { fn: Logic.method(:xor_op), arity: { 2 => %w[Boolean Boolean] } },
        "implies" => { fn: Logic.method(:implies_op), arity: { 2 => %w[Boolean Boolean] } },
        "+" => { fn: Math.method(:plus), arity: { 2 => %w[Any Any] }, nullable: true },
        "-" => { fn: Math.method(:minus), arity: { 2 => %w[Any Any] }, nullable: true },
        "*" => { fn: Math.method(:mul), arity: { 2 => %w[Number Number] }, nullable: true },
        "/" => { fn: Math.method(:div), arity: { 2 => %w[Number Number] }, nullable: true },
        "div" => { fn: Math.method(:intdiv), arity: { 2 => %w[Number Number] }, nullable: true },
        "mod" => { fn: Math.method(:mod), arity: { 2 => %w[Number Number] }, nullable: true },
        "&" => { fn: Math.method(:amp), arity: { 2 => %w[String String] } },
        "iif" => { fn: Misc.method(:iif), arity: { 2 => %w[Expr Expr], 3 => %w[Expr Expr Expr] } },
        "trace" => { fn: Misc.method(:trace), arity: { 0 => [], 1 => ["String"], 2 => %w[String Expr] } },
        "toInteger" => { fn: Misc.method(:to_integer) },
        "toDecimal" => { fn: Misc.method(:to_decimal) },
        "toString" => { fn: Misc.method(:to_string) },
        "toDate" => { fn: Misc.method(:to_date) },
        "toDateTime" => { fn: Misc.method(:to_date_time) },
        "toTime" => { fn: Misc.method(:to_time) },
        "toQuantity" => { fn: Misc.method(:to_quantity), arity: { 0 => [], 1 => ["String"] } },
        "toBoolean" => { fn: Misc.method(:to_boolean) },
        "convertsToBoolean" => { fn: Misc.method(:converts_to_boolean) },
        "convertsToInteger" => { fn: Misc.method(:converts_to_integer) },
        "convertsToDecimal" => { fn: Misc.method(:converts_to_decimal) },
        "convertsToString" => { fn: Misc.method(:converts_to_string) },
        "convertsToDate" => { fn: Misc.method(:converts_to_date) },
        "convertsToDateTime" => { fn: Misc.method(:converts_to_date_time) },
        "convertsToTime" => { fn: Misc.method(:converts_to_time) },
        "convertsToQuantity" => { fn: Misc.method(:converts_to_quantity) },
        "aggregate" => { fn: Aggregate.method(:aggregate), arity: { 1 => ["Expr"], 2 => %w[Expr Any] } },
        "sum" => { fn: Aggregate.method(:sum) },
        "avg" => { fn: Aggregate.method(:avg) },
        "min" => { fn: Aggregate.method(:min) },
        "max" => { fn: Aggregate.method(:max) },
        "now" => { fn: Datetime.method(:now) },
        "today" => { fn: Datetime.method(:today) },
        "timeOfDay" => { fn: Datetime.method(:time_of_day) }
      }.freeze

      REGISTRY = REGISTRY_CORE.merge(REGISTRY_STRINGS_AND_MATH).freeze
    end
  end
end
