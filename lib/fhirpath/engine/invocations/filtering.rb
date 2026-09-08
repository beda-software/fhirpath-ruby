# frozen_string_literal: true

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of `where`/`select`/`repeat`/`ofType`/`single`/`first`/`last`/`tail`/`take`/
      # `skip` from fhirpath-py's fhirpathpy/engine/invocations/filtering.py.
      module Filtering
        class << self
          def single(_ctx, coll)
            return coll if coll.length == 1
            return [] if coll.empty?

            { "$status" => "error", "$error" => "Expected single" }
          end

          def first(_ctx, coll)
            coll.empty? ? [] : coll.first
          end

          def last(_ctx, coll)
            coll.empty? ? [] : coll.last
          end

          def tail(_ctx, coll)
            coll.empty? ? [] : coll[1..]
          end

          def take(_ctx, coll, num)
            coll.empty? ? [] : coll.first([num.to_i, 0].max)
          end

          def skip(_ctx, coll, num)
            coll.empty? ? [] : coll.drop([num.to_i, 0].max)
          end

          def where(ctx, data, expr)
            return [] unless data.is_a?(::Array)

            result = data.each_with_index.select do |item, index|
              ctx[:index] = index
              truthy?(expr.call(item))
            end.map(&:first)

            Util.flatten(result)
          end

          def select(ctx, data, expr)
            return [] unless data.is_a?(::Array)

            result = data.each_with_index.map do |item, index|
              ctx[:index] = index
              expr.call(item)
            end

            Util.flatten(result)
          end

          def repeat(_ctx, data, expr)
            return [] unless data.is_a?(::Array)

            result = []
            seen = []
            items = data.dup

            advance_repeat(items, seen, result, expr) until items.empty?

            result
          end

          def of_type(_ctx, coll, type_info)
            coll.select { |value| Nodes::TypeInfo.from_value(value).is_(type_info) }
          end

          private

          def truthy?(result)
            return false if result.empty?

            value = result.first
            !(value.nil? || value == false)
          end

          def advance_repeat(items, seen, result, expr)
            next_item = items.shift
            new_items = expr.call(next_item).reject { |elem| seen.include?(elem) }
            return if new_items.empty?

            seen.concat(new_items)
            result.concat(new_items)
            items.concat(new_items)
          end
        end
      end
    end
  end
end
