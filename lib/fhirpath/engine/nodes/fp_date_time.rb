# frozen_string_literal: true

require "time"

module Fhirpath
  module Engine
    module Nodes
      # Minimal Ruby port of fhirpath-py's FP_DateTime (fhirpathpy/engine/nodes.py): printing a
      # date/time literal back out verbatim, and precision-aware equality (per the FHIRPath spec,
      # two date/times are only comparable when both are specified to the same precision).
      class FPDateTime
        FORMAT = /
          \A(?<year>\d{4})
          (?:-(?<month>\d{2})(?:-(?<day>\d{2}))?)?
          (?:T(?<hour>\d{2})(?::(?<minute>\d{2})(?::(?<second>\d{2})(?:\.\d+)?)?)?
            (?<timezone>Z|[+-]\d{2}:\d{2})?
          )?\z
        /x

        COMPONENTS = %i[year month day hour minute second].freeze
        DEFAULTS = { year: "0", month: "1", day: "1", hour: "0", minute: "0", second: "0" }.freeze

        attr_reader :source

        def initialize(source)
          @source = source
          @match = FORMAT.match(source)
          raise Fhirpath::Error, "Invalid date/time literal: #{source}" unless @match
        end

        def to_s
          source
        end

        # How many of year/month/day/hour/minute/second were specified.
        def precision
          COMPONENTS.count { |component| @match[component] }
        end

        # Only true/false; unlike the FHIRPath spec (which returns empty when precision
        # differs), that case isn't exercised yet, so it's simply not equal here.
        def ==(other)
          return false unless other.is_a?(FPDateTime)
          return false if precision != other.precision

          to_instant == other.to_instant
        end

        def to_instant
          Time.new(*COMPONENTS.map { |component| component_value(component) }, timezone).getutc
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
