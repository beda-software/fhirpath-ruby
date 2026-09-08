# frozen_string_literal: true

require "time"

module Fhirpath
  module Engine
    module Nodes
      # Minimal Ruby port of fhirpath-py's FP_Time (fhirpathpy/engine/nodes.py): printing a time
      # literal back out verbatim, and the FHIRPath equals() comparison
      # (https://hl7.org/fhirpath/#equals). Mirrors FPDateTime's approach (see there for the
      # precision-comparison rationale); the leading "T" is optional since both a `@Thh:mm...`
      # literal (stripped of "@T" before construction) and a raw "Thh:mm..." string (as stored
      # in a resource) must parse the same.
      class FPTime
        FORMAT = /
          \AT?(?<hour>\d{2})
          (?::(?<minute>\d{2})
            (?::(?<second>\d{2})(?:\.(?<fraction>\d+))?)?
          )?
          (?<timezone>Z|[+-]\d{2}:\d{2})?
        \z/x

        COMPONENTS = %i[hour minute second].freeze
        DEFAULTS = { hour: "0", minute: "0", second: "0" }.freeze
        TIME_READERS = { hour: :hour, minute: :min, second: :sec }.freeze

        attr_reader :source

        def initialize(source)
          @source = source
          @match = FORMAT.match(source)
          raise Fhirpath::Error, "Invalid time literal: #{source}" unless @match
        end

        def to_s
          source
        end

        def ==(other)
          equals(other) == true
        end

        # See FPDateTime#equals for the precision-comparison rationale.
        def equals(other)
          return false unless other.is_a?(self.class)

          fields = shared_fields(other)
          self_precision, other_precision = precisions(other, fields)

          return time_of_day == other.time_of_day if self_precision == other_precision

          compare_up_to_min_precision(other, fields, [self_precision, other_precision].min)
        end

        def to_instant
          Time.new(2000, 1, 1, component_value(:hour), component_value(:minute), second_value, timezone).getutc
        end

        # A timezone shift can roll the fixed reference date in to_instant over to the next (or
        # previous) day; unlike DateTime, Time comparisons only care about wall-clock time, so
        # this discards the date and keeps just seconds-since-midnight (with sub-second
        # precision) — matching Python's `datetime.time()` truncation.
        def time_of_day
          utc = to_instant
          (utc.hour * 3600) + (utc.min * 60) + utc.sec + utc.subsec
        end

        # See FPDateTime#compare for the precision-comparison rationale.
        def compare(other)
          fields = shared_fields(other)
          self_precision, other_precision = precisions(other, fields)

          return time_of_day <=> other.time_of_day if self_precision == other_precision

          compare_by_field(other, fields, [self_precision, other_precision].min)
        end

        protected

        def normalized
          @normalized ||= begin
            utc = to_instant
            COMPONENTS.to_h { |c| [c, @match[c] ? utc.public_send(TIME_READERS[c]) : nil] }
          end
        end

        def timezone?
          !@match[:timezone].nil?
        end

        private

        def shared_fields(other)
          COMPONENTS.reject { |c| normalized[c].nil? && other.normalized[c].nil? }
        end

        def precisions(other, fields)
          [fields.count { |c| !normalized[c].nil? }, fields.count { |c| !other.normalized[c].nil? }]
        end

        def compare_up_to_min_precision(other, fields, min_precision)
          fields.first(min_precision).each do |c|
            return nil if normalized[c].nil? || other.normalized[c].nil?
            return false if normalized[c] != other.normalized[c]
          end

          return false if timezone? != other.timezone?

          nil
        end

        def compare_by_field(other, fields, min_precision)
          fields.first(min_precision).each do |c|
            return -1 if normalized[c].nil? || other.normalized[c].nil?

            ordinal = normalized[c] <=> other.normalized[c]
            return ordinal unless ordinal.zero?
          end

          nil
        end

        def component_value(component)
          (@match[component] || DEFAULTS[component]).to_i
        end

        def second_value
          component_value(:second) + (@match[:fraction] ? Rational("0.#{@match[:fraction]}") : 0)
        end

        def timezone
          value = @match[:timezone]
          value.nil? || value == "Z" ? "+00:00" : value
        end
      end
    end
  end
end
