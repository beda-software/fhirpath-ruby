# frozen_string_literal: true

require_relative "strings_encoding"

module Fhirpath
  module Engine
    module Invocations
      # Ruby port of fhirpath-py's fhirpathpy/engine/invocations/strings.py (FHIRPath spec
      # section 5.6). `encode`/`decode` live in strings_encoding.rb. `escape`/`unescape` aren't
      # ported (fhirpath-py's own tests disable them too, as "not implemented yet").
      module Strings
        class << self
          def index_of(_ctx, coll, substr)
            string = ensure_string_singleton(coll)
            string.index(substr) || -1
          end

          def substring(_ctx, coll, start, length = nil)
            string = ensure_string_singleton(coll)
            return [] if start.is_a?(::Array) || start.nil?

            start = start.to_i
            return [] if start.negative? || start >= string.length
            return string[start..] if length.nil? || length.is_a?(::Array)

            string[start, length.to_i]
          end

          def starts_with(_ctx, coll, prefix)
            return [] if Util.empty?(prefix)

            string = ensure_string_singleton(coll)
            return false if string.empty? || !prefix.is_a?(::String)

            string.start_with?(prefix)
          end

          def ends_with(_ctx, coll, suffix)
            return [] if Util.empty?(suffix)

            string = ensure_string_singleton(coll)
            return false if string.empty? || !suffix.is_a?(::String)

            string.end_with?(suffix)
          end

          def contains(_ctx, coll, substr)
            ensure_string_singleton(coll).include?(substr)
          end

          def upper(_ctx, coll)
            ensure_string_singleton(coll).upcase
          end

          def lower(_ctx, coll)
            ensure_string_singleton(coll).downcase
          end

          # `pattern` is matched literally, not as a regex — see `replace_matches` for the
          # regex-based counterpart.
          def replace(_ctx, coll, pattern, repl)
            string = ensure_string_singleton(coll)
            return repl + string.chars.join(repl) + repl if pattern == "" && repl.is_a?(::String)
            return [] if blank?(string) || blank?(pattern)

            string.gsub(pattern, repl)
          end

          def matches(_ctx, coll, regex)
            return [] if blank?(regex) || coll.empty?

            string = ensure_string_singleton(coll)
            string.match?(Regexp.new(regex, Regexp::MULTILINE))
          end

          def replace_matches(_ctx, coll, regex, repl)
            string = ensure_string_singleton(coll)
            return [] if regex.is_a?(::Array) || repl.is_a?(::Array)

            # FHIRPath substitution refers to capture groups as $1, $2, ...; Ruby (like Python)
            # spells that \1, \2, ... in a gsub replacement string.
            substitution = repl.gsub(/\$(\d+)/) { "\\#{::Regexp.last_match(1)}" }
            string.gsub(Regexp.new(regex), substitution)
          end

          def length(_ctx, coll)
            ensure_string_singleton(coll).length
          end

          def to_chars(_ctx, coll)
            return [] if coll.empty?

            ensure_string_singleton(coll).chars
          end

          def split(_ctx, coll, delimiter)
            # -1 keeps trailing empty fields, matching Python's str.split (Ruby's split drops
            # them by default).
            ensure_string_singleton(coll).split(delimiter, -1)
          end

          def trim(_ctx, coll)
            ensure_string_singleton(coll).strip
          end

          def join(_ctx, coll, separator = "")
            return [] if coll.empty?

            coll.map { |item| string_value(item) }.join(separator)
          end

          private

          def ensure_string_singleton(coll)
            if coll.length == 1
              data = Util.get_data(coll.first)
              return data if data.is_a?(::String)

              raise Fhirpath::Error, "Expected string, but got #{data.inspect}"
            end

            raise Fhirpath::Error, "Expected string, but got #{coll.inspect}"
          end

          def string_value(item)
            data = Util.get_data(item)
            raise Fhirpath::Error, "Join requires a collection of strings." unless data.is_a?(::String)

            data
          end

          def blank?(value)
            value.respond_to?(:empty?) ? value.empty? : value.nil?
          end
        end
      end
    end
  end
end
