# frozen_string_literal: true

require_relative "invocations/navigation"
require_relative "invocations/filtering"
require_relative "invocations/equality"

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
        "=" => { fn: Equality.method(:equal), arity: { 2 => %w[Any Any] }, nullable: true }
      }.freeze
    end
  end
end
