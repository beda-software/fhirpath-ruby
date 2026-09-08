# frozen_string_literal: true

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of `=`/`!=`/`~`/`<`/`>` from fhirpath-py's
      # fhirpathpy/engine/invocations/equality.py. `!~`/typecheck's inequality type-coercion
      # aren't exercised yet.
      module Equality
        class << self
          def equal(_ctx, left, right)
            return false if Util.empty?(left) || Util.empty?(right)
            return false if left.length != right.length

            Util.get_data(left[0]) == Util.get_data(right[0])
          end

          def unequal(ctx, left, right)
            !equal(ctx, left, right)
          end

          # Unlike `=`, empty operands aren't handled by the invocation registry's generic
          # "nullable" short-circuit — equivalence defines its own emptiness semantics ({} ~ {}
          # is true), so this handles it directly.
          def equival(_ctx, left, right)
            return true if Util.empty?(left) && Util.empty?(right)
            return false if Util.empty?(left) || Util.empty?(right)

            a = Util.get_data(left[0])
            b = Util.get_data(right[0])

            return a.equivalent?(b) if a.is_a?(Nodes::FPQuantity) && b.is_a?(Nodes::FPQuantity)

            a == b
          end

          def gt(_ctx, left, right)
            Util.get_data(left[0]) > Util.get_data(right[0])
          end

          def lt(_ctx, left, right)
            Util.get_data(left[0]) < Util.get_data(right[0])
          end
        end
      end
    end
  end
end
