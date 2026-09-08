# frozen_string_literal: true

require_relative "invocations/navigation"
require_relative "invocations/filtering"
require_relative "invocations/equality"
require_relative "invocations/existence"
require_relative "invocations/combining"

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of the base `invocation_registry` built in fhirpath-py's
      # fhirpathpy/engine/invocations/__init__.py. Only entries needed so far are ported; see
      # the category modules required above.
      REGISTRY = {
        "where" => { fn: Filtering.method(:where), arity: { 1 => ["Expr"] } },
        "children" => { fn: Navigation.method(:children) },
        "descendants" => { fn: Navigation.method(:descendants) },
        "combine" => { fn: Combining.method(:combine), arity: { 1 => ["AnyAtRoot"] } },
        "|" => { fn: Combining.method(:union), arity: { 2 => %w[Any Any] } },
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
        "<" => { fn: Equality.method(:lt), arity: { 2 => %w[Any Any] }, nullable: true },
        ">" => { fn: Equality.method(:gt), arity: { 2 => %w[Any Any] }, nullable: true }
      }.freeze
    end
  end
end
