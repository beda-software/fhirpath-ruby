# frozen_string_literal: true

module Fhirpath
  module Engine
    module Nodes
      # Reopens FPQuantity (see fp_quantity.rb) to add `#deep_equal`, used by `=`/`~` when
      # comparing a raw FHIR Quantity element (converted to a System.Quantity by quoting its
      # UCUM `code` as-is — e.g. code "a" becomes unit "'a'", see ResourceNode#convert_data)
      # against a literal using the calendar *word* form ("year") — those must compare equal,
      # unlike plain `==` (which deliberately excludes "'a'" from year/month equality). Mirrors
      # fhirpath-py's FP_Quantity.deep_equal; see Equality#pairwise_equal?/Equality#equivalence.
      class FPQuantity
        # Mirrors fhirpath-py's FP_Quantity.mapUCUMCodeToTimeUnits.values() — the bare calendar
        # words a converted-from-FHIR-Quantity's unit (always a quoted UCUM code) is compared
        # against via #deep_equal rather than plain #==.
        CALENDAR_WORDS = %w[year month week day hour minute second millisecond].freeze

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
      end
    end
  end
end
