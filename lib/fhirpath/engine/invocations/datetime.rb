# frozen_string_literal: true

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of `now`/`today`/`timeOfDay` from fhirpath-py's
      # fhirpathpy/engine/invocations/datetime.py. fhirpath-py caches these on a module-level
      # `constants` singleton reset at the start of each evaluate() call, so that repeated calls
      # within one expression see the same instant; here that's just a `ctx` entry, since `ctx`
      # is already fresh per evaluate() call.
      module Datetime
        class << self
          def now(ctx, _data)
            snapshot(ctx).strftime("%Y-%m-%dT%H:%M:%S.%L%:z")
          end

          def today(ctx, _data)
            snapshot(ctx).strftime("%Y-%m-%d")
          end

          def time_of_day(ctx, _data)
            snapshot(ctx).strftime("%H:%M:%S.%L")
          end

          private

          def snapshot(ctx)
            ctx[:now_time] ||= Time.now
          end
        end
      end
    end
  end
end
