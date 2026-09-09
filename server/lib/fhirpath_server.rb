# frozen_string_literal: true

require "fhirpath"

require_relative "fhirpath_server/result_formatter"
require_relative "fhirpath_server/request_parser"
require_relative "fhirpath_server/response_builder"
require_relative "fhirpath_server/api"

# Standalone Grape web server exposing fhirpath-rb over the fhirpath-lab server API
# (https://github.com/brianpos/fhirpath-lab/blob/develop/server-api.md), mirroring
# fhirpath-py-server (https://github.com/beda-software/fhirpath-py-server). Not part of the
# fhirpath-rb gem — it only consumes fhirpath-rb's public API (Fhirpath.evaluate).
module FhirpathServer
end
