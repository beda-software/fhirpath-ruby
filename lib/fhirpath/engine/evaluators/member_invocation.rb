# frozen_string_literal: true

module Fhirpath
  module Engine
    # MemberInvocation evaluator (e.g. the ".value" in "Observation.value") and its reducer,
    # ported from fhirpath-py's member_invocation/create_reduce_member_invocation
    # (fhirpathpy/engine/evaluators/__init__.py). Split out of evaluators.rb to keep that file's
    # module body short; reopens the same Evaluators module.
    module Evaluators
      class << self
        def member_invocation(ctx, parent_data, node)
          key = Engine.do_eval(ctx, parent_data, node["children"][0])[0].delete("`")
          return [] unless parent_data.is_a?(::Array)

          matches = resource_type_matches(parent_data, key)
          return matches if matches

          model = ctx[:model]
          parent_data.reduce([]) { |acc, res| reduce_member(acc, res, model, key) }
        end

        private

        # The special case where a capitalized path segment (e.g. the leading "Observation" in
        # "Observation.value") filters a collection of raw resource hashes by resourceType,
        # rather than looking up an ordinary property.
        def resource_type_matches(parent_data, key)
          return nil unless Util.capitalized?(key)

          filtered = parent_data.select { |item| item["resourceType"] == key }
          filtered.map { |item| Nodes::ResourceNode.create_node(item, key) }
        rescue ::NoMethodError, ::TypeError
          # parent_data holds nodes that don't support `[]` (e.g. already ResourceNodes) — fall
          # through to the ordinary member lookup below, matching fhirpath-py's TypeError catch.
          nil
        end

        def reduce_member(acc, res, model, key)
          res = Nodes::ResourceNode.create_node(res)
          child_path, full_path, actual_types = member_lookup_paths(res, key, model)
          to_add, to_add_ext, child_path = member_lookup_value(res, key, actual_types, child_path)
          child_path = remap(model, "path2Type", child_path)

          acc = append_member_value(acc, to_add, child_path, full_path)
          append_member_value(acc, to_add_ext, child_path, full_path)
        end

        def member_lookup_paths(res, key, model)
          child_path = res.path ? "#{res.path}.#{key}" : "_.#{key}"
          full_path = (res.prop_name ? "#{res.prop_name}.#{key}" : child_path).delete("_")
          child_path = remap(model, "pathsDefinedElsewhere", child_path)
          actual_types = model.is_a?(::Hash) ? model.dig("choiceTypePaths", child_path) : nil

          [child_path, full_path, actual_types]
        end

        def member_lookup_value(res, key, actual_types, child_path)
          return [res.data.value, nil, child_path] if res.data.is_a?(Nodes::FPQuantity)
          return choice_type_value(res, key, actual_types, child_path) if choice_type?(res, actual_types)
          return hash_value(res, key, child_path) if res.data.is_a?(::Hash)
          return [res.data.length, nil, child_path] if key == "length" && res.data.respond_to?(:length)

          [nil, nil, child_path]
        end

        def choice_type?(res, actual_types)
          actual_types && !actual_types.empty? && res.data.is_a?(::Hash)
        end

        def hash_value(res, key, child_path)
          child_path = "Extension" if key == "extension"
          [res.data[key], res.data["_#{key}"], child_path]
        end

        def choice_type_value(res, key, actual_types, child_path)
          actual_types.each do |actual_type|
            field = "#{key}#{actual_type}"
            to_add = res.data[field]
            to_add_ext = res.data["_#{field}"]
            next if to_add.nil? && to_add_ext.nil?

            return [to_add, to_add_ext, child_path + actual_type]
          end

          [nil, nil, child_path]
        end

        def remap(model, table, child_path)
          return child_path unless model.is_a?(::Hash) && model[table]

          model[table].fetch(child_path, child_path)
        end

        def append_member_value(acc, value, child_path, full_path)
          return acc unless Util.some?(value)

          if value.is_a?(::Array)
            mapped = value.each_with_index.map do |item, i|
              Nodes::ResourceNode.create_node(item, child_path, prop_name: "#{full_path}[#{i}]", index: i)
            end
            acc + mapped
          else
            acc + [Nodes::ResourceNode.create_node(value, child_path, prop_name: full_path)]
          end
        end
      end
    end
  end
end
