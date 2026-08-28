# frozen_string_literal: true

require "cgi"
require "uri"

module BoningNet
  module ProjectDetail
    module Components
      module MarkdownValidator
        INLINE_TYPES = %i[
          p text strong em a codespan entity typographic_sym smart_quote br
        ].freeze
        CALLOUT_TYPES = (INLINE_TYPES + %i[ul ol li]).freeze
        LINK_ATTRIBUTES = %w[href title].freeze
        SAFE_LINK_SCHEMES = %w[http https mailto tel].freeze
        SLASH_LIKE_CHARACTERS = ["/", "\\"].freeze
        URL_ENTITY_REPLACEMENTS = {
          "&Tab;" => "\t",
          "&NewLine;" => "\n",
          "&colon;" => ":",
          "&sol;" => "/",
          "&bsol;" => "\\"
        }.freeze
        URL_ENTITY_PATTERN = Regexp.union(URL_ENTITY_REPLACEMENTS.keys).freeze

        module_function

        def allowed_tree?(element, types:)
          types.include?(element.type) &&
            element.children.all? { |child| allowed_tree?(child, types: types) }
        end

        def validate_safety!(root, component:, context:, line:)
          each_element(root).each do |element|
            validate_attributes!(element, component: component, context: context, line: line)
            next unless element.type == :a
            next if safe_link_url?(element.attr.fetch("href", ""))

            context.error!(
              "#{component} link URL must be relative or use http, https, mailto, or tel",
              line: line
            )
          end
        end

        def validate_attributes!(element, component:, context:, line:)
          allowed = element.type == :a ? LINK_ATTRIBUTES : []
          unexpected = element.attr.keys - allowed
          ial = element.options[:ial]
          return if unexpected.empty? && (ial.nil? || ial.empty?)

          context.error!("#{component} does not allow inline attribute lists", line: line)
        end
        private_class_method :validate_attributes!

        def safe_link_url?(value)
          return false unless value.is_a?(String) && !value.empty?

          decoded = decode_url_entities(value)
          return false if decoded.match?(/[\u0000-\u001f\u007f]/)
          return false if network_path_prefix?(decoded)

          uri = URI.parse(decoded)
          return true unless uri.scheme

          SAFE_LINK_SCHEMES.include?(uri.scheme.downcase)
        rescue URI::InvalidURIError
          false
        end
        private_class_method :safe_link_url?

        def decode_url_entities(value)
          CGI.unescapeHTML(value.gsub(URL_ENTITY_PATTERN, URL_ENTITY_REPLACEMENTS))
        end
        private_class_method :decode_url_entities

        def network_path_prefix?(value)
          prefix = value[0, 2]
          prefix.length == 2 &&
            prefix.each_char.all? { |character| SLASH_LIKE_CHARACTERS.include?(character) }
        end
        private_class_method :network_path_prefix?

        def each_element(root)
          [root, *root.children.flat_map { |child| each_element(child) }]
        end
        private_class_method :each_element
      end
    end
  end
end
