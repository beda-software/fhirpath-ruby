# frozen_string_literal: true

require "time"

module Fhirpath
  module Engine
    module Nodes
      # Minimal Ruby port of fhirpath-py's FP_Time (fhirpathpy/engine/nodes.py): printing a time
      # literal back out verbatim, and precision-aware equality. Mirrors FPDateTime's approach.
      # The leading "T" is optional since both a `@Thh:mm...` literal (stripped of "@T" before
      # construction) and a raw "Thh:mm..." string (as stored in a resource) must parse the same.
      class FPTime
        FORMAT = /
          \AT?(?<hour>\d{2})
          (?::(?<minute>\d{2})
            (?::(?<second>\d{2})(?:\.\d+)?)?
          )?
          (?<timezone>Z|[+-]\d{2}:\d{2})?
        \z/x

        COMPONENTS = %i[hour minute second].freeze
        DEFAULTS = { hour: "0", minute: "0", second: "0" }.freeze

        attr_reader :source

        def initialize(source)
          @source = source
          @match = FORMAT.match(source)
          raise Fhirpath::Error, "Invalid time literal: #{source}" unless @match
        end

        def to_s
          source
        end

        def precision
          COMPONENTS.count { |component| @match[component] }
        end

        def ==(other)
          return false unless other.is_a?(FPTime)
          return false if precision != other.precision

          to_instant == other.to_instant
        end

        def to_instant
          Time.new(2000, 1, 1, *COMPONENTS.map { |component| component_value(component) }, timezone).getutc
        end

        private

        def component_value(component)
          (@match[component] || DEFAULTS[component]).to_i
        end

        def timezone
          value = @match[:timezone]
          value.nil? || value == "Z" ? "+00:00" : value
        end
      end
    end
  end
end
