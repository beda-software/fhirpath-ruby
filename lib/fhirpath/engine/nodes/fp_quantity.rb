# frozen_string_literal: true

require "bigdecimal"

module Fhirpath
  module Engine
    module Nodes
      # Minimal Ruby port of fhirpath-py's FP_Quantity (fhirpathpy/engine/nodes.py): printing
      # back as "value unit", exposing `.value` through member invocation, and the calendar
      # duration/time-unit conversion-factor equality used by `distinct`/`repeat`
      # (https://hl7.org/fhirpath/#equals). The general UCUM-conversion fallback (`conv_unit_to`)
      # isn't ported yet, so mismatched units outside these two categories compare unequal.
      class FPQuantity
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

        attr_reader :value, :unit

        def initialize(value, unit)
          @value = value
          @unit = unit
        end

        def to_s
          "#{value} #{unit}"
        end

        def ==(other)
          return false unless other.is_a?(FPQuantity)
          return exact_match?(other) unless same_convertible_category?(other)

          scaled(self) == scaled(other)
        end

        private

        def exact_match?(other)
          value == other.value && unit == other.unit
        end

        def same_convertible_category?(other)
          (YEAR_MONTH_FACTORS.key?(unit) && YEAR_MONTH_FACTORS.key?(other.unit)) ||
            (TIME_FACTORS.key?(unit) && TIME_FACTORS.key?(other.unit))
        end

        def scaled(quantity)
          factor = YEAR_MONTH_FACTORS[quantity.unit] || TIME_FACTORS[quantity.unit]
          quantity.value * factor
        end
      end
    end
  end
end
