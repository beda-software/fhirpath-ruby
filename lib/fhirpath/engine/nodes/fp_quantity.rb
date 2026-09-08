# frozen_string_literal: true

require "bigdecimal"

module Fhirpath
  module Engine
    module Nodes
      # Ruby port of fhirpath-py's FP_Quantity (fhirpathpy/engine/nodes.py): printing back as
      # "value unit", exposing `.value` through member invocation, the calendar duration/
      # time-unit conversion-factor equality used by `=`/`distinct`/`repeat`/`intersect`
      # (https://hl7.org/fhirpath/#equals), the more lenient `equivalent?` used by `~`, and
      # `conv_unit_to` (used by `toQuantity(unit)` for explicit unit conversion, and by
      # `general_equivalent?`/`deep_equal` below for cross-unit comparisons).
      class FPQuantity
        # Bare calendar-duration words and already-quoted UCUM codes all normalize to the
        # quoted UCUM code, mirroring fhirpath-py's FP_Quantity.timeUnitsToUCUM.
        TIME_UNITS_TO_UCUM = {
          "years" => "'a'", "months" => "'mo'", "weeks" => "'wk'", "days" => "'d'",
          "hours" => "'h'", "minutes" => "'min'", "seconds" => "'s'", "milliseconds" => "'ms'",
          "year" => "'a'", "month" => "'mo'", "week" => "'wk'", "day" => "'d'",
          "hour" => "'h'", "minute" => "'min'", "second" => "'s'", "millisecond" => "'ms'",
          "'a'" => "'a'", "'mo'" => "'mo'", "'wk'" => "'wk'", "'d'" => "'d'",
          "'h'" => "'h'", "'min'" => "'min'", "'s'" => "'s'", "'ms'" => "'ms'"
        }.freeze

        # Which quantity units are valid for date/time arithmetic (FPDateTime#plus/FPTime#plus),
        # and which canonical duration unit each one means. Mirrors fhirpath-py's
        # FP_Quantity._arithmetic_duration_units — deliberately narrower than TIME_UNITS_TO_UCUM
        # above: the quoted UCUM year/month codes ("'a'"/"'mo'") are NOT valid here (only the
        # bare words "year"/"month" are), per https://hl7.org/fhirpath/#datetime-arithmetic.
        ARITHMETIC_DURATION_UNITS = {
          "years" => :year, "months" => :month, "weeks" => :week, "days" => :day,
          "hours" => :hour, "minutes" => :minute, "seconds" => :second, "milliseconds" => :millisecond,
          "year" => :year, "month" => :month, "week" => :week, "day" => :day,
          "hour" => :hour, "minute" => :minute, "second" => :second, "millisecond" => :millisecond,
          "'wk'" => :week, "'d'" => :day, "'h'" => :hour,
          "'min'" => :minute, "'s'" => :second, "'ms'" => :millisecond
        }.freeze

        YEAR_MONTH_FACTORS = {
          "years" => BigDecimal("12"), "year" => BigDecimal("12"), "'a'" => BigDecimal("12"),
          "months" => BigDecimal("1"), "month" => BigDecimal("1"), "'mo'" => BigDecimal("1")
        }.freeze

        TIME_FACTORS = {
          "weeks" => BigDecimal("604800000"), "week" => BigDecimal("604800000"), "'wk'" => BigDecimal("604800000"),
          "days" => BigDecimal("86400000"), "day" => BigDecimal("86400000"), "'d'" => BigDecimal("86400000"),
          "hours" => BigDecimal("3600000"), "hour" => BigDecimal("3600000"), "'h'" => BigDecimal("3600000"),
          "minutes" => BigDecimal("60000"), "minute" => BigDecimal("60000"), "'min'" => BigDecimal("60000"),
          "seconds" => BigDecimal("1000"), "second" => BigDecimal("1000"), "'s'" => BigDecimal("1000"),
          "milliseconds" => BigDecimal("1"), "millisecond" => BigDecimal("1"), "'ms'" => BigDecimal("1")
        }.freeze

        # conv_unit_to's year/month table is deliberately narrower than YEAR_MONTH_FACTORS above
        # (only the quoted UCUM codes) — matches fhirpath-py's separate _year_month_conversion_factor.
        CONV_YEAR_MONTH_FACTORS = { "'a'" => BigDecimal("12"), "'mo'" => BigDecimal("1") }.freeze

        LENGTH_FACTORS = {
          "'m'" => BigDecimal("1"), "'cm'" => BigDecimal("0.01"), "'mm'" => BigDecimal("0.001")
        }.freeze

        WEIGHT_FACTORS = {
          "'kg'" => BigDecimal("1"), "lbs" => BigDecimal("0.453592"), "'[lb_av]'" => BigDecimal("0.453592")
        }.freeze

        attr_reader :value, :unit

        def initialize(value, unit)
          @value = value
          @unit = unit
        end

        def to_s
          "#{Util.format_number(value)} #{unit}"
        end

        # Per https://hl7.org/fhirpath/#equals, a UCUM "'a'" (annum, a fixed Julian year) is
        # never equal to a calendar "year"/"years" even though both are 12 months for
        # `equivalent?` purposes — only `=` makes this distinction, not `~`.
        def ==(other)
          return false unless other.is_a?(FPQuantity)
          return false if year_month_category?(other) && (unit == "'a'" || other.unit == "'a'")

          equivalent?(other)
        end

        def equivalent?(other)
          return false unless other.is_a?(FPQuantity)
          return general_equivalent?(other) unless same_convertible_category?(other)

          scaled(self) == scaled(other)
        end

        def self.conv_unit_to(from_unit, value, to_unit)
          convert_by_table(CONV_YEAR_MONTH_FACTORS, from_unit, value, to_unit) ||
            convert_by_table(TIME_FACTORS, from_unit, value, to_unit) ||
            convert_by_table(LENGTH_FACTORS, from_unit, value, to_unit) ||
            convert_weight(from_unit, value, to_unit) ||
            convert_mass(from_unit, value, to_unit)
        end

        def self.convert_by_table(factors, from_unit, value, to_unit)
          from_factor = factors[from_unit]
          to_factor = factors[to_unit]
          return nil unless from_factor && to_factor

          new(from_factor * value / to_factor, to_unit)
        end
        private_class_method :convert_by_table

        def self.convert_weight(from_unit, value, to_unit)
          from_factor = WEIGHT_FACTORS[from_unit]
          to_factor = WEIGHT_FACTORS[to_unit]
          return nil unless from_factor && to_factor

          converted = (from_factor * value) / to_factor
          new(converted.round(0, BigDecimal::ROUND_UP), to_unit)
        end
        private_class_method :convert_weight

        private

        def exact_match?(other)
          value == other.value && unit == other.unit
        end

        def year_month_category?(other)
          YEAR_MONTH_FACTORS.key?(unit) && YEAR_MONTH_FACTORS.key?(other.unit)
        end

        def same_convertible_category?(other)
          year_month_category?(other) || (TIME_FACTORS.key?(unit) && TIME_FACTORS.key?(other.unit))
        end

        def scaled(quantity)
          factor = YEAR_MONTH_FACTORS[quantity.unit] || TIME_FACTORS[quantity.unit]
          quantity.value * factor
        end
      end
    end
  end
end
