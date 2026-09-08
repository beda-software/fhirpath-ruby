# frozen_string_literal: true

require "bigdecimal"

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of `iif`/`toInteger`/`toDecimal`/`toString`/`toDate`/`toDateTime`/`toTime`/
      # `toQuantity` from fhirpath-py's fhirpathpy/engine/invocations/misc.py. `toBoolean` and
      # the convertsTo* family aren't exercised yet.
      module Misc
        INT_REGEX = /\A[+-]?\d+\z/
        NUM_REGEX = /\A[+-]?\d+(\.\d+)?\z/
        QUANTITY_REGEX = /\A([+-]?\d+(?:\.\d+)?)\s*(?:('[^']+')|([a-zA-Z]+))?\z/

        class << self
          def iif(_ctx, data, cond, on_true, on_false = nil)
            return on_true.call(data) if Util.true?(cond.call(data))
            return on_false.call(data) if on_false

            []
          end

          # Logs the input collection under `label` (via ctx[:trace_fn] if the caller supplied
          # one, else stdout) and returns it unchanged.
          def trace(ctx, coll, label = "")
            if ctx[:trace_fn].respond_to?(:call)
              ctx[:trace_fn].call(label, coll)
            else
              puts "TRACE:[#{label}] #{coll}"
            end

            coll
          end

          def to_integer(_ctx, coll)
            return [] if coll.length != 1

            integer_value(Util.get_data(coll.first))
          end

          def to_decimal(_ctx, coll)
            return [] if coll.length != 1

            value = Util.get_data(coll.first)
            return BigDecimal(0) if value == false
            return BigDecimal(1) if value == true
            return BigDecimal(value.to_s) if value.is_a?(::Numeric)
            return BigDecimal(value) if value.is_a?(::String) && NUM_REGEX.match?(value)

            []
          end

          def to_string(_ctx, coll)
            return [] if coll.length != 1

            Util.format_number(Util.get_data(coll.first))
          end

          def to_date_time(_ctx, coll)
            raise Fhirpath::Error, "to_date_time called for a collection of length #{coll.length}" if coll.length > 1
            return [] if coll.empty?

            Nodes::FPDateTime.new(Util.get_data(coll.first))
          end

          # fhirpath-py's to_date is, as written, identical to to_date_time (no truncation to
          # date-only precision) — mirrored as-is.
          def to_date(ctx, coll)
            to_date_time(ctx, coll)
          end

          def to_time(_ctx, coll)
            raise Fhirpath::Error, "to_time called for a collection of length #{coll.length}" if coll.length > 1
            return [] if coll.empty?

            Nodes::FPTime.new(Util.get_data(coll.first))
          end

          def to_quantity(_ctx, coll, to_unit = nil)
            if coll.length > 1
              raise Fhirpath::Error, "Could not convert to quantity: input collection contains multiple items"
            end
            return [] if coll.empty?

            to_unit = normalize_unit(to_unit) if to_unit
            result = parse_quantity(Util.val_data_converted(coll.first))
            result = convert_to_unit(result, to_unit) if result && to_unit

            result || []
          end

          private

          def integer_value(value)
            return 0 if value == false
            return 1 if value == true
            return value if value.is_a?(::Numeric) && value.to_i == value
            return value.to_i if value.is_a?(::String) && INT_REGEX.match?(value)

            []
          end

          def normalize_unit(unit)
            Nodes::FPQuantity::TIME_UNITS_TO_UCUM.key?(unit) ? unit : "'#{unit}'"
          end

          def convert_to_unit(result, to_unit)
            return result if result.unit == to_unit

            Nodes::FPQuantity.conv_unit_to(result.unit, result.value, to_unit)
          end

          def parse_quantity(value)
            return Nodes::FPQuantity.new(value, "'1'") if value.is_a?(::Numeric)
            return value if value.is_a?(Nodes::FPQuantity)
            return Nodes::FPQuantity.new(value ? 1 : 0, "'1'") if [true, false].include?(value)
            return parse_quantity_string(value) if value.is_a?(::String)

            nil
          end

          def parse_quantity_string(value)
            match = QUANTITY_REGEX.match(value)
            return nil unless match

            time = match[3]
            return nil if time && !Nodes::FPQuantity::TIME_UNITS_TO_UCUM.key?(time)

            Nodes::FPQuantity.new(BigDecimal(match[1]), match[2] || time || "'1'")
          end
        end
      end
    end
  end
end
