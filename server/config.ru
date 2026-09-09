# frozen_string_literal: true

require "rack/cors"
require_relative "lib/fhirpath_server"

# Mirrors fhirpath-py-server's main.py CORS setup (aiohttp_cors), which allow-lists the
# fhirpath-lab web UI's own origins.
ALLOWED_ORIGINS = [
  "https://fhirpath-lab.com",
  "https://dev.fhirpath-lab.com",
  "https://hackweek.fhirpath-lab.com",
  "https://fhirpath-lab.azurewebsites.net",
  "https://fhirpath-lab-dev.azurewebsites.net",
  "http://localhost:3000"
].freeze

use Rack::Cors do
  allow do
    origins(*ALLOWED_ORIGINS)
    resource "*", headers: :any, methods: :any, credentials: true
  end
end

run FhirpathServer::API
