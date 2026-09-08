# frozen_string_literal: true

require_relative "equivalence"
require_relative "inequality"

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of `=`/`!=` from fhirpath-py's fhirpathpy/engine/invocations/equality.py.
      # `~`/`!~` (equivalence) live in equivalence.rb and `<`/`>`/`<=`/`>=` in inequality.rb,
      # both of which reopen this module (and use datetime_value?/coerce_datetime, below).
      module Equality
        class << self
          def equal(_ctx, left, right)
            equality(left, right)
          end

          def unequal(_ctx, left, right)
            result = equality(left, right)
            result.nil? ? nil : !result
          end

          private

          # Per https://hl7.org/fhirpath/#equals. Returns true/false, or nil (spec: empty) when
          # a DateTime/Time comparison can't be resolved at a shared precision. Collections with
          # more than one item are compared pairwise, in order (fhirpath-py's own equality()
          # only ever compares the first pair — a narrower reading no test here happens to
          # probe — so this compares every pair instead, per the spec text quoted in this task's
          # own fixture: "Each item must be equal. Comparison is order dependent.").
          def equality(left, right)
            return false if Util.empty?(left) || Util.empty?(right)

            x0 = Util.get_data(left.first)
            y0 = Util.get_data(right.first)
            return datetime_equals(x0, y0) if datetime_value?(x0) || datetime_value?(y0)
            return false if left.length != right.length

            pairwise_equal?(left, right)
          end

          def pairwise_equal?(left, right)
            left.zip(right).all? { |a, b| Util.get_data(a) == Util.get_data(b) }
          end

          def datetime_value?(value)
            value.is_a?(Nodes::FPDateTime) || value.is_a?(Nodes::FPTime)
          end

          def datetime_equals(left_value, right_value)
            x = coerce_datetime(left_value)
            y = coerce_datetime(right_value)
            return false if x.nil? || y.nil?

            x.equals(y)
          end

          # A string operand being compared against an already-parsed FPDateTime/FPTime is
          # itself parsed as a date/time (trying DateTime first, then Time) before comparing;
          # anything else (including an unparseable string) can't be compared this way.
          def coerce_datetime(value)
            return value if datetime_value?(value)
            return nil unless value.is_a?(::String)

            parse_date_time(value) || parse_time(value)
          end

          def parse_date_time(value)
            Nodes::FPDateTime.new(value)
          rescue Fhirpath::Error
            nil
          end

          def parse_time(value)
            Nodes::FPTime.new(value)
          rescue Fhirpath::Error
            nil
          end
        end
      end
    end
  end
end
