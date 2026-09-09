# frozen_string_literal: true

module FhirpathServer
  # Builds the JSON served at GET /config.json, so fhirpath-lab
  # (https://fhirpath-lab.com) can register this server as a selectable engine via its
  # `?config=` URL parameter without being merged into fhirpath-lab's own built-in engine
  # registry. See
  # https://github.com/brianpos/fhirpath-lab/blob/develop/docs/custom-configuration.md
  module ConfigBuilder
    ENGINES = {
      "r4" => { legacy_name: "fhirpath-rb (R4)", fhir_version: "R4", operation: "$fhirpath" },
      "r5" => { legacy_name: "fhirpath-rb (R5)", fhir_version: "R5", operation: "$fhirpath-r5" }
    }.freeze

    COMMON_ENGINE_DETAILS = {
      "name" => "fhirpath-rb",
      "appInsightsEngineName" => "fhirpath-rb",
      "publisher" => "Beda Software",
      "description" => "Ruby implementation of FHIRPath (port of fhirpath-py)",
      "supportsAST" => false,
      "external" => true,
      "githubRepo" => "https://github.com/beda-software/fhirpath-ruby"
    }.freeze

    def self.call(base_url:)
      ENGINES.each_value.with_object({ "engines" => {} }) do |engine, config|
        config_setting = "fhirpath_rb_#{engine[:fhir_version].downcase}"
        config["engines"][engine[:legacy_name]] = COMMON_ENGINE_DETAILS.merge(
          "legacyName" => engine[:legacy_name],
          "fhirVersion" => engine[:fhir_version],
          "configSetting" => config_setting
        )
        config[config_setting] = "#{force_https(base_url)}/fhir/#{engine[:operation]}"
      end
    end

    # Puma always serves plain HTTP (see Dockerfile); in production this app is only ever
    # reachable through a TLS-terminating reverse proxy in front of it, so `base_url`'s scheme
    # (derived from the possibly-missing/misconfigured X-Forwarded-Proto header) can't be
    # trusted - force https rather than advertise engine URLs fhirpath-lab can't actually use.
    def self.force_https(base_url)
      return base_url unless ENV["RACK_ENV"] == "production"

      base_url.sub(/\Ahttp:/, "https:")
    end
    private_class_method :force_https
  end
end
