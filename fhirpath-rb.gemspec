# frozen_string_literal: true

require_relative "lib/fhirpath/version"

Gem::Specification.new do |spec|
  spec.name = "fhirpath-rb"
  spec.version = Fhirpath::VERSION
  spec.authors = ["beda.software"]
  spec.email = ["ilya@beda.software"]

  spec.summary = "FHIRPath implementation in Ruby"
  spec.description = "A Ruby port of fhirpath-py (https://github.com/beda-software/fhirpath-py), " \
                      "implementing the FHIRPath expression language (https://hl7.org/fhirpath/)."
  spec.homepage = "https://github.com/beda-software/fhirpath-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ server/ .git .github appveyor Gemfile])
    end
  end
  # The native extension's sources are generated from lib/fhirpath/parser/FHIRPath.g4 by
  # `rake parser:setup` (see rakelib/parser.rake) and are gitignored, so `git ls-files` above
  # never sees them. They still have to ship inside the released gem — otherwise `extconf.rb`
  # has nothing to compile on the installing machine — so they're added explicitly here. Run
  # `rake parser:setup` before `gem build`/`rake release` for this to have anything to glob.
  antlr4_runtime_src = "ext/fhir_path_parser/antlr4-upstream/runtime/Cpp/runtime/src"
  generated_globs = [
    "ext/fhir_path_parser/fhir_path_parser.cpp",
    "ext/fhir_path_parser/antlrgen/*.{cpp,h}",
    "#{antlr4_runtime_src}/*.{cpp,h}",
    "#{antlr4_runtime_src}/{atn,dfa,misc,support,tree,tree/pattern,tree/xpath}/*.{cpp,h}"
  ]
  spec.files += generated_globs.flat_map { |glob| Dir.glob(glob, base: __dir__) }
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  # "ext/fhir_path_parser" is only needed so `require "fhir_path_parser"` resolves during local
  # development, where `rake parser:setup compile` builds the .bundle in place; for an installed
  # gem, RubyGems adds its own extension build directory (which holds the real compiled
  # artifact) to the load path automatically.
  spec.require_paths = ["lib", "ext/fhir_path_parser"]
  spec.extensions = ["ext/fhir_path_parser/extconf.rb"]

  spec.add_dependency "base64"
  spec.add_dependency "bigdecimal"
  spec.add_dependency "fhir_models", "~> 5.1"
  spec.add_dependency "rice", "~> 4.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
