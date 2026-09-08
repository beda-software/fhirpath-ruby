# frozen_string_literal: true

require_relative "invocations/navigation"
require_relative "invocations/filtering"
require_relative "invocations/equality"
require_relative "invocations/existence"
require_relative "invocations/combining"
require_relative "invocations/math"
require_relative "invocations/subsetting"
require_relative "invocations/misc"

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
        "<" => { fn: Equality.method(:lt), arity: { 2 => %w[Any Any] }, nullable: true },
        ">" => { fn: Equality.method(:gt), arity: { 2 => %w[Any Any] }, nullable: true },
        "+" => { fn: Math.method(:plus), arity: { 2 => %w[Any Any] }, nullable: true },
        "iif" => { fn: Misc.method(:iif), arity: { 2 => %w[Expr Expr], 3 => %w[Expr Expr Expr] } },
        "toInteger" => { fn: Misc.method(:to_integer) },
        "toDecimal" => { fn: Misc.method(:to_decimal) },
        "toString" => { fn: Misc.method(:to_string) },
        "toDateTime" => { fn: Misc.method(:to_date_time) },
        "toTime" => { fn: Misc.method(:to_time) },
        "toQuantity" => { fn: Misc.method(:to_quantity), arity: { 0 => [], 1 => ["String"] } }
      }.freeze
    end
  end
end
