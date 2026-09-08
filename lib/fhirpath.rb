# frozen_string_literal: true

require "fhir_models"

require_relative "fhirpath/version"
require_relative "fhirpath/parser"
require_relative "fhirpath/engine"
require_relative "fhirpath/models"

# Ruby implementation of FHIRPath (https://hl7.org/fhirpath/), a port of fhirpath-py
# (https://github.com/beda-software/fhirpath-py).
module Fhirpath
  class Error < StandardError; end

  def self.evaluate(resource, path, context = {}, model = nil, options = {})
    apply_parsed_path(resource, Parser.parse(path), context, model, options)
  end

  def self.compile(path, model = nil, options = {})
    node = Parser.parse(path)
    ->(resource, context = nil) { apply_parsed_path(resource, node, context || {}, model, options) }
  end

  def self.compile_as_array(expression, model = nil)
    compile(expression, model)
  end

  def self.compile_as_first(expression, model = nil)
    path = compile_as_array(expression, model)
    ->(resource, context = nil) { path.call(resource, context).first }
  end

  # Ruby port of fhirpath-py's apply_parsed_path (fhirpathpy/__init__.py): builds the
  # evaluation context and resolves the AST, then unwraps internal ResourceNode wrappers back
  # into plain data.
  def self.apply_parsed_path(resource, node, context, model, _options)
    data_root = Engine::Util.arraify(resource)
    ctx = {
      root: data_root,
      vars: { "context" => resource }.merge(context || {}),
      model: model.is_a?(::String) ? Models[model] : model,
      user_invocation_table: {}
    }

    visit(Engine.do_eval(ctx, data_root, node["children"][0]))
  end
  private_class_method :apply_parsed_path

  # Resolves ResourceNode instances back into plain data, dropping internal
  # primitive-extension-only placeholders (`{"extension" => [...]}`) along the way.
  def self.visit(node)
    data = Engine::Util.get_data(node)

    return visit_array(data) if data.is_a?(::Array)
    return data.transform_values { |value| visit(value) } if data.is_a?(::Hash)

    data
  end
  private_class_method :visit

  def self.visit_array(items)
    items.each_with_object([]) do |item, acc|
      visited = visit(item)
      acc << visited unless visited.is_a?(::Hash) && visited.keys == ["extension"]
    end
  end
  private_class_method :visit_array
end
