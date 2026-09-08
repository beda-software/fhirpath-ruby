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
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/fhir_path_parser/extconf.rb"]

  spec.add_dependency "fhir_models", "~> 5.1"
  spec.add_dependency "rice", "~> 4.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
