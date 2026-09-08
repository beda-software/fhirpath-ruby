# frozen_string_literal: true

module Fhirpath
  module Engine
    module Nodes
      # Reopens FPQuantity (see fp_quantity.rb) to add the mass (g/mg) conv_unit_to category,
      # `#deep_equal` (used by `=`/`~` when comparing a raw FHIR Quantity element — converted to
      # a System.Quantity by quoting its UCUM `code` as-is, e.g. code "a" becomes unit "'a'", see
      # ResourceNode#convert_data — against a literal using the calendar *word* form "year";
      # those must compare equal, unlike plain `==`, which deliberately excludes "'a'" from
      # year/month equality), and `#equivalent?`'s general (non-year/month, non-weeks/days/time)
      # fallback for `=`. Mirrors fhirpath-py's FP_Quantity.deep_equal and the "else" branch of
      # FP_Quantity.__eq__; see Equality#pairwise_equal?/Equality#equivalence.
      class FPQuantity
        MASS_FACTORS = { "'g'" => BigDecimal("1"), "'mg'" => BigDecimal("0.001") }.freeze

        # Mirrors fhirpath-py's FP_Quantity.mapUCUMCodeToTimeUnits.values() — the bare calendar
        # words a converted-from-FHIR-Quantity's unit (always a quoted UCUM code) is compared
        # against via #deep_equal rather than plain #==.
        CALENDAR_WORDS = %w[year month week day hour minute second millisecond].freeze

        def self.convert_mass(from_unit, value, to_unit)
          from_factor = MASS_FACTORS[from_unit]
          to_factor = MASS_FACTORS[to_unit]
          return nil unless from_factor && to_factor

          converted = (from_factor * value) / to_factor
          new(converted.round(0, BigDecimal::ROUND_HALF_UP), to_unit)
        end
        private_class_method :convert_mass

        def deep_equal(other)
          return self == other unless other.is_a?(FPQuantity)
          return equivalent?(other) if year_month_category?(other)
          return self == other if unit == other.unit

          round_trip_equal?(other)
        end

        private

        def round_trip_equal?(other)
          converted = self.class.conv_unit_to(unit, value, other.unit)
          return self == other unless converted

          reverse_converted = self.class.conv_unit_to(converted.unit, converted.value, unit)
          return self == other unless reverse_converted

          value == reverse_converted.value && unit == reverse_converted.unit
        end

        # Mirrors fhirpath-py's FP_Quantity.__eq__ "else" branch: units outside the year/month
        # and weeks/days/time categories (e.g. length, weight, mass) are compared by converting
        # one side to the other's unit — falling back to an exact value+unit match if they
        # aren't in any shared convertible category at all.
        def general_equivalent?(other)
          return exact_match?(other) if unit == other.unit

          converted = self.class.conv_unit_to(unit, value, other.unit)
          return exact_match?(other) unless converted

          other.value == converted.value && other.unit == converted.unit
        end
      end
    end
  end
end
