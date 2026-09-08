# frozen_string_literal: true

require "date"

module Fhirpath
  module Engine
    module Nodes
      # Reopens FPDateTime (see fp_date_time.rb) to add `#plus` — ports fhirpath-py's
      # FP_TimeBase#plus for FP_DateTime (https://hl7.org/fhirpath/#datetime-arithmetic): adding
      # a duration quantity respects this literal's own precision — a quantity finer than what's
      # specified is converted up to that precision using calendar approximations (365 days/
      # year, 30 days/month, ...) rather than exact calendar math, per the spec's rules for
      # imprecise date/time arithmetic. `value` is always truncated to an integer first (the
      # spec: "the decimal portion... is ignored").
      class FPDateTime
        PRECISION_FORMATS = {
          1 => "%Y", 2 => "%Y-%m", 3 => "%Y-%m-%d",
          4 => "%Y-%m-%dT%H", 5 => "%Y-%m-%dT%H:%M", 6 => "%Y-%m-%dT%H:%M:%S"
        }.freeze

        def plus(quantity)
          value = quantity.value.to_i
          unit = FPQuantity::ARITHMETIC_DURATION_UNITS[quantity.unit]
          raise Fhirpath::Error, "Cannot add #{quantity} to #{self}" unless unit

          precision = date_precision
          result = add_duration(base_time, unit, value, precision)
          self.class.new(result.strftime(PRECISION_FORMATS.fetch(precision, PRECISION_FORMATS[6])))
        end

        private

        DATE_ARITHMETIC_FIELDS = %i[year month day hour minute second fraction].freeze
        SUB_HOUR_DIVISORS = { minute: 60, second: 3600, millisecond: 3_600_000 }.freeze

        def date_precision
          DATE_ARITHMETIC_FIELDS.count { |c| @match[c] }
        end

        def base_time
          Time.utc(component_value(:year), component_value(:month), component_value(:day),
                   component_value(:hour), component_value(:minute), component_value(:second))
        end

        def add_duration(base, unit, value, precision)
          case unit
          when :year then add_months(base, value * 12)
          when :month then add_months(base, value)
          when :day, :week then add_day_or_week(base, unit, value, precision)
          when :hour then add_hour(base, value, precision)
          when :minute, :second, :millisecond then add_sub_hour(base, unit, value, precision)
          end
        end

        def add_day_or_week(base, unit, value, precision)
          days_value = unit == :week ? value * 7 : value
          case precision
          when 1 then add_months(base, trunc_div(days_value, 365) * 12)
          when 2 then add_months(base, trunc_div(days_value, 30))
          else base + (days_value * 86_400)
          end
        end

        def add_hour(base, value, precision)
          case precision
          when 2 then add_months(base, trunc_div(value, 24 * 30))
          when 3 then base + (trunc_div(value, 24) * 86_400)
          when 7 then base + (value * 3600)
          else
            raise Fhirpath::Error, "Cannot add hours at precision #{precision} to #{self}"
          end
        end

        def add_sub_hour(base, unit, value, precision)
          case precision
          when 4 then base + (trunc_div(value, SUB_HOUR_DIVISORS[unit]) * 3600)
          when 5 then add_sub_hour_at_minute_precision(base, unit, value)
          when 7 then add_sub_hour_at_full_precision(base, unit, value)
          else
            raise Fhirpath::Error, "Cannot add #{unit} at precision #{precision} to #{self}"
          end
        end

        def add_sub_hour_at_minute_precision(base, unit, value)
          minutes = case unit
                    when :minute then value
                    when :second then trunc_div(value, 60)
                    when :millisecond then trunc_div(value, 60_000)
                    end
          base + (minutes * 60)
        end

        def add_sub_hour_at_full_precision(base, unit, value)
          case unit
          when :minute then base + (value * 60)
          when :second then base + value
          when :millisecond then base + (value / 1000.0)
          end
        end

        def add_months(time, months)
          date = Date.new(time.year, time.month, time.day) >> months
          Time.utc(date.year, date.month, date.day, time.hour, time.min, time.sec)
        end

        def trunc_div(numerator, denominator)
          numerator.fdiv(denominator).truncate
        end
      end
    end
  end
end
