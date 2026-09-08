# frozen_string_literal: true

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of `children`/`descendants` from fhirpath-py's
      # fhirpathpy/engine/invocations/navigation.py.
      module Navigation
        class << self
          def children(ctx, coll)
            coll.reduce([]) { |acc, res| reduce_children(ctx, acc, res, exclude_primitive_extensions: true) }
          end

          def descendants(ctx, coll)
            res = []
            current = reduce_all_children(ctx, coll)

            until current.empty?
              res += current
              current = reduce_all_children(ctx, current)
            end

            res
          end

          private

          def reduce_all_children(ctx, coll)
            coll.reduce([]) { |acc, item| reduce_children(ctx, acc, item, exclude_primitive_extensions: false) }
          end

          def reduce_children(ctx, acc, res, exclude_primitive_extensions:)
            model = ctx[:model]
            data = Util.get_data(res)
            res = Nodes::ResourceNode.create_node(res)

            data = data.each_with_index.to_h { |value, i| [i, value] } if data.is_a?(::Array)
            return acc unless data.is_a?(::Hash)

            data.each_key do |prop|
              next if prop.start_with?("_") && exclude_primitive_extensions

              acc = reduce_child(model, acc, res, prop, data[prop])
            end

            acc
          end

          def reduce_child(model, acc, res, prop, value)
            child_path, full_path = child_paths(model, res, prop)

            if value.is_a?(::Array)
              value.each_with_index do |item, i|
                acc += [Nodes::ResourceNode.create_node(item, child_path, prop_name: "#{full_path}[#{i}]", index: i)]
              end
            else
              acc += [Nodes::ResourceNode.create_node(value, child_path, prop_name: full_path)]
            end

            acc
          end

          def child_paths(model, res, prop)
            child_path = res.path ? "#{res.path}.#{prop}" : ""
            full_path = (res.prop_name ? "#{res.prop_name}.#{prop}" : child_path).delete("_")

            child_path = "Extension" if prop == "extension"
            child_path = remap(model, "pathsDefinedElsewhere", child_path)
            child_path = remap(model, "path2Type", child_path)
            full_path = choice_type_full_path(model, res, prop, child_path) || full_path

            [child_path, full_path]
          end

          def remap(model, table, child_path)
            return child_path unless model.is_a?(::Hash) && model[table]

            model[table].fetch(child_path, child_path)
          end

          # When a property's name already carries its (shrunk-to-a-bare-type) childPath as a
          # suffix (e.g. prop "valueString" vs childPath "string"), it's really a choice-type
          # field — fullPath should point at the shared field name ("value"), not "valueString".
          def choice_type_full_path(model, res, prop, child_path)
            return nil unless prop.downcase.end_with?(child_path.downcase) && prop.length > child_path.length

            base_prop = prop[0...-child_path.length]
            return nil if choice_types(model, "#{res.path}.#{base_prop}").empty?

            "#{res.prop_name}.#{base_prop}"
          end

          def choice_types(model, alt_prop_name)
            return [] unless model.is_a?(::Hash)

            (model["choiceTypePaths"] || {})[alt_prop_name] || []
          end
        end
      end
    end
  end
end
