# frozen_string_literal: true

require "fhir_models"

require_relative "fhirpath/version"

module Fhirpath
  class Error < StandardError; end

  def self.evaluate(_resource, _path, _context = {}, _model = nil, _options = {})
    []
  end

  def self.compile(_path, _model = nil, _options = {})
    ->(_resource, _context = nil) { [] }
  end

  def self.compile_as_array(expression, model = nil)
    compile(expression, model)
  end

  def self.compile_as_first(expression, model = nil)
    path = compile_as_array(expression, model)
    ->(resource, context = nil) { path.call(resource, context).first }
  end
end
