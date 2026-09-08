# frozen_string_literal: true

require "bigdecimal"

module Fhirpath
  module Engine
    module Nodes
      # Reopens FPTime (see fp_time.rb) to add `#plus` — see FPDateTime#plus for the overall
      # approach. Unlike FPDateTime, arithmetic here ignores this literal's timezone entirely
      # (adding to the wall-clock digits, keeping whatever offset was already there) and wraps
      # past midnight — matching fhirpath-py's FP_TimeBase#plus for FP_Time, which only supports
      # hour/minute/second/millisecond durations (never day-and-above, since a bare time has no
      # date to carry a day rollover into).
      class FPTime
        def plus(quantity)
          value = quantity.value.to_i
          unit = FPQuantity::ARITHMETIC_DURATION_UNITS[quantity.unit]
          raise Fhirpath::Error, "Cannot add #{quantity} to #{self}" unless time_unit?(unit)

          precision = time_precision
          delta = time_delta(unit, value, precision, quantity)
          wrapped = (total_seconds + delta) % 86_400
          self.class.new("T#{format_clock(wrapped, precision)}#{@match[:timezone]}")
        end

        private

        TIME_ARITHMETIC_UNITS = %i[hour minute second millisecond].freeze
        TIME_ARITHMETIC_FIELDS = %i[hour minute second fraction].freeze

        def time_unit?(unit)
          TIME_ARITHMETIC_UNITS.include?(unit)
        end

        def time_precision
          TIME_ARITHMETIC_FIELDS.count { |c| @match[c] }
        end

        def total_seconds
          whole = (component_value(:hour) * 3600) + (component_value(:minute) * 60) + component_value(:second)
          Util.to_big_decimal(whole) + (@match[:fraction] ? BigDecimal("0.#{@match[:fraction]}") : 0)
        end

        # Below full (hour:minute:second[.millisecond]) precision, a duration finer than the
        # literal's own precision is converted up to whole minutes/hours first (truncating, per
        # fhirpath-py); at full precision "second" additions keep the quantity's own fractional
        # value (the spec: sub-second arithmetic isn't approximated).
        def time_delta(unit, value, precision, quantity)
          case precision
          when 2 then time_delta_at_hour_minute_precision(unit, value)
          when 3, 4 then time_delta_at_second_precision(unit, value, quantity)
          else
            raise Fhirpath::Error, "Cannot add #{unit} at precision #{precision} to #{self}"
          end
        end

        def time_delta_at_hour_minute_precision(unit, value)
          case unit
          when :hour then value * 3600
          when :minute then value * 60
          when :second then trunc_div(value, 60) * 60
          when :millisecond then trunc_div(value, 60_000) * 60
          end
        end

        def time_delta_at_second_precision(unit, value, quantity)
          case unit
          when :hour then value * 3600
          when :minute then value * 60
          when :second then quantity.value
          when :millisecond then Util.to_big_decimal(value) / 1000
          end
        end

        def trunc_div(numerator, denominator)
          numerator.fdiv(denominator).truncate
        end

        # Precision 2 (hour:minute only, no seconds in the source literal) keeps the output at
        # that same granularity — printing an explicit ":00" seconds field here would make this
        # result's precision look finer than the original, which throws off equals()'s
        # differing-precision comparison against another precision-2 literal (only fields both
        # sides actually specify may be compared; an extra field one side has and the other
        # doesn't is `nil`/empty, not a match, per https://hl7.org/fhirpath/#equals).
        def format_clock(seconds_value, precision)
          whole = seconds_value.to_i
          hour = whole / 3600
          minute = (whole % 3600) / 60
          clock = "#{two_digits(hour)}:#{two_digits(minute)}"
          return clock if precision == 2

          "#{clock}:#{format_seconds_field(whole % 60, seconds_value - whole)}"
        end

        def format_seconds_field(second, frac)
          return two_digits(second) if frac.zero?

          "#{two_digits(second)}.#{frac_digits(frac)}"
        end

        def two_digits(number)
          number.to_s.rjust(2, "0")
        end

        def frac_digits(frac)
          frac.to_s("F").sub(/\A0\./, "").sub(/0+\z/, "")
        end
      end
    end
  end
end
