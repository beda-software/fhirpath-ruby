# frozen_string_literal: true

require "bigdecimal"

module Fhirpath
  module Engine
    # Literal-term evaluators (number/string/boolean/null/quantity/date-time), ported from
    # fhirpath-py's fhirpathpy/engine/evaluators/__init__.py. Split out of evaluators.rb to keep
    # that file's module body short; reopens the same Evaluators module.
    module Evaluators
      class << self
        def number_literal(_ctx, _parent_data, node)
          value = BigDecimal(node["text"])
          int_value = value.to_i
          [value == int_value ? int_value : value]
        end

        def string_literal(_ctx, _parent_data, node)
          text = node["text"].sub(/\A['"]/, "").sub(/['"]\z/, "")
          text = text.gsub("\\'", "'")
                     .gsub("\\`", "`")
                     .gsub('\\"', '"')
                     .gsub("\\r", "\r")
                     .gsub("\\n", "\n")
                     .gsub("\\t", "\t")
                     .gsub("\\f", "\f")
                     .gsub("\\\\", "\\")
          [text.gsub(/\\u(\h{4})/) { [::Regexp.last_match(1).to_i(16)].pack("U") }]
        end

        def boolean_literal(_ctx, _parent_data, node)
          [node["text"] == "true"]
        end

        def null_literal(_ctx, _parent_data, _node)
          []
        end

        def quantity_literal(_ctx, _parent_data, node)
          value_node = node["children"][0]
          value = BigDecimal(value_node["terminalNodeText"][0])
          unit_node = value_node["children"][0]
          unit = quantity_unit(unit_node)

          [Nodes::FPQuantity.new(value, unit)]
        end

        def date_time_literal(_ctx, _parent_data, node)
          [Nodes::FPDateTime.new(node["text"][1..])]
        end

        def time_literal(_ctx, _parent_data, node)
          [Nodes::FPTime.new(node["text"][2..])]
        end

        private

        # A Unit node's terminalNodeText holds a quoted UCUM unit (e.g. "'mo'") directly; for a
        # calendar duration unit (e.g. "years") it instead has a PluralDateTimePrecision child
        # whose terminalNodeText holds the word.
        def quantity_unit(unit_node)
          return unit_node["terminalNodeText"].first if unit_node["terminalNodeText"]&.any?
          return unit_node["children"].first["terminalNodeText"].first if unit_node["children"]&.any?

          nil
        end
      end
    end
  end
end
