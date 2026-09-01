# frozen_string_literal: true

require "kramdown"

module BoningNet
  module ProjectDetail
    module EntityDecoder
      ENTITY_REFERENCE = /&(?:#([0-9]+)|#[xX]([0-9A-Fa-f]+)|([A-Za-z][A-Za-z0-9]+));/

      module_function

      def decode_once(value)
        return value unless value.is_a?(String)

        value.gsub(ENTITY_REFERENCE) do |reference|
          code_point = if Regexp.last_match(1)
                         Regexp.last_match(1).to_i(10)
                       elsif Regexp.last_match(2)
                         Regexp.last_match(2).to_i(16)
                       else
                         Kramdown::Utils::Entities.entity(Regexp.last_match(3)).code_point
                       end
          code_point.chr(Encoding::UTF_8)
        rescue Kramdown::Error, RangeError
          reference
        end
      end
    end
  end
end
