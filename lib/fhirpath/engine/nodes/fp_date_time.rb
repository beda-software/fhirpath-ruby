# frozen_string_literal: true

require "time"

module Fhirpath
  module Engine
    module Nodes
      # Minimal Ruby port of fhirpath-py's FP_DateTime (fhirpathpy/engine/nodes.py): printing a
      # date/time literal back out verbatim, and the FHIRPath equals() comparison
      # (https://hl7.org/fhirpath/#equals): each specified precision level is compared in turn,
      # starting from year; a mismatch there is `false`, but if one side simply doesn't specify
      # a precision level the other does, the result is empty (`nil` here) rather than `false`.
      # `#plus` (date/time + duration quantity arithmetic) lives in fp_date_time_arithmetic.rb,
      # which reopens this class.
      class FPDateTime
        FORMAT = /
          \A(?<year>\d{4})
          (?:-(?<month>\d{2})(?:-(?<day>\d{2}))?)?
          (?:T(?<hour>\d{2})(?::(?<minute>\d{2})(?::(?<second>\d{2})(?:\.(?<fraction>\d+))?)?)?
            (?<timezone>Z|[+-]\d{2}:\d{2})?
          )?\z
        /x

        COMPONENTS = %i[year month day hour minute second].freeze
        DEFAULTS = { year: "0", month: "1", day: "1", hour: "0", minute: "0", second: "0" }.freeze
        TIME_READERS = { year: :year, month: :month, day: :day, hour: :hour, minute: :min, second: :sec }.freeze

        attr_reader :source

        def initialize(source)
          @source = source
          @match = FORMAT.match(source)
          raise Fhirpath::Error, "Invalid date/time literal: #{source}" unless @match
        end

        def to_s
          source
        end

        def ==(other)
          equals(other) == true
        end

        # Per https://hl7.org/fhirpath/#equals: compare each precision level present on either
        # side, starting from year. A field both sides specify but disagree on is `false`; a
        # field only one side specifies is `nil` (spec: empty). If every field up to the lower
        # precision matches and both sides specify the same precision, fall back to comparing
        # the full instant (this is what distinguishes e.g. differing sub-second precision).
        def equals(other)
          return false unless other.is_a?(self.class)

          fields = shared_fields(other)
          self_precision, other_precision = precisions(other, fields)

          return to_instant == other.to_instant if self_precision == other_precision

          compare_up_to_min_precision(other, fields, [self_precision, other_precision].min)
        end

        def to_instant
          Time.new(component_value(:year), component_value(:month), component_value(:day),
                   component_value(:hour), component_value(:minute), second_value, timezone).getutc
        end

        # Per https://hl7.org/fhirpath/#comparison: -1/0/1, or nil (spec: empty) when ordering
        # can't be resolved at a shared precision (fields match up to the lower precision, but
        # neither is a prefix of the other so which sorts first is undefined).
        def compare(other)
          fields = shared_fields(other)
          self_precision, other_precision = precisions(other, fields)

          return to_instant <=> other.to_instant if self_precision == other_precision

          compare_by_field(other, fields, [self_precision, other_precision].min)
        end

        protected

        # UTC-shifted calendar fields, revealing only the components this literal actually
        # specifies — lets e.g. "22:00-04:00" and "06:00+04:00" compare correctly across the
        # day boundary the timezone shift crosses.
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
