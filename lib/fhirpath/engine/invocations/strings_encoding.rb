# frozen_string_literal: true

require "base64"

module Fhirpath
  module Engine
    module Invocations
      # `encode`/`decode` from fhirpath-py's fhirpathpy/engine/invocations/strings.py. Split
      # out of strings.rb to keep that file's module body short; reopens the same Strings
      # module.
      module Strings
        class << self
          def encode(_ctx, coll, encoding)
            return [] if coll.empty?

            value = Util.get_data(coll.first)
            return [] if blank?(value)

            encode_value(value, encoding)
          end

          def decode(_ctx, coll, encoding)
            return [] if coll.empty?

            value = Util.get_data(coll.first)
            return [] if blank?(value)

            decode_value(value, encoding)
          end

          private

          def encode_value(value, encoding)
            case encoding
            when "urlbase64", "base64url"
              Base64.strict_encode64(value).tr("+/", "-_")
            when "base64"
              Base64.strict_encode64(value)
            when "hex"
              value.each_byte.map { |byte| byte.to_s(16).rjust(2, "0") }.join
            else
              []
            end
          end

          def decode_value(value, encoding)
            case encoding
            when "urlbase64", "base64url"
              Base64.strict_decode64(value.tr("-_", "+/")).force_encoding(::Encoding::UTF_8)
            when "base64"
              Base64.strict_decode64(value).force_encoding(::Encoding::UTF_8)
            when "hex"
              decode_hex(value)
            else
              []
            end
          end

          def decode_hex(value)
            raise Fhirpath::Error, "Decode 'hex' requires an even number of characters." if value.length.odd?

            value.each_char.each_slice(2).map { |pair| pair.join.to_i(16).chr }.join
          end
        end
      end
    end
  end
end
