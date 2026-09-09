# syntax=docker/dockerfile:1

# Standalone server, distributed separately from the fhirpath-rb gem: it installs fhirpath-rb
# from rubygems.org (see Gemfile) rather than vendoring this repo's lib/. FHIRPATH_RB_VERSION
# pins the exact gem version to install; the release workflow passes the version that was just
# published, so the built image and the gem release stay in lockstep.
ARG RUBY_VERSION=3.4

FROM ruby:${RUBY_VERSION}-slim AS builder

ARG FHIRPATH_RB_VERSION
ENV FHIRPATH_RB_VERSION=${FHIRPATH_RB_VERSION}

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copied before `bundle install` (rather than Gemfile/Gemfile.lock alone, which would be
# friendlier to layer caching) so that when FHIRPATH_RB_VERSION overrides the checked-in
# Gemfile.lock, the rewritten lock file bundler leaves behind is the one that ends up in the
# image - not clobbered by a later COPY of the original, checked-in Gemfile.lock.
COPY . .
RUN bundle config set --local without "development test" \
    && bundle install --jobs 4 --retry 3

FROM ruby:${RUBY_VERSION}-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
      libstdc++6 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 1000 fhirpath \
    && useradd --create-home --uid 1000 --gid 1000 fhirpath

WORKDIR /app

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app

RUN chown -R fhirpath:fhirpath /app
USER fhirpath

ENV RACK_ENV=production
EXPOSE 8081

CMD ["bundle", "exec", "puma", "-p", "8081", "config.ru"]
