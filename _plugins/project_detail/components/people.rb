# frozen_string_literal: true

require "kramdown"
require_relative "base"
require_relative "markdown_validator"

module BoningNet
  module ProjectDetail
    module Components
      class People < Base
        REQUIRED_KEYS = %w[name role image].freeze
        ALLOWED_KEYS = (REQUIRED_KEYS + ["url"]).freeze

        register_as "people"

        def compile(node, context)
          source = validated_source_attribute(node, context)
          reject_body!(node, context)
          group = resolve_group(source, node, context)
          items = group.map { |entry| compile_person(entry, node, context) }

          {
            "type" => self.class.type,
            "source" => source,
            "items" => items
          }
        end

        private

        def validated_source_attribute(node, context)
          unexpected = (node.attributes.keys - ["source"]).first
          if unexpected
            context.error!(
              %(people does not accept attribute "#{unexpected}"),
              line: node.start_line
            )
          end

          source = node.attributes["source"]
          unless source.is_a?(String) && !source.strip.empty?
            context.error!("people requires a nonblank source attribute", line: node.start_line)
          end
          source
        end

        def reject_body!(node, context)
          return if node.body.strip.empty?

          context.error!("people does not accept body content", line: node.start_line)
        end

        def resolve_group(source, node, context)
          people = context.frontmatter.fetch("people", {})
          unless people.is_a?(Hash)
            context.error!("people frontmatter must be a mapping", line: node.start_line)
          end
          unless people.key?(source)
            context.error!(%(people source "#{source}" was not found), line: node.start_line)
          end

          group = people[source]
          unless group.is_a?(Array) && !group.empty?
            context.error!(
              %(people source "#{source}" must be a nonempty array),
              line: node.start_line
            )
          end
          group
        end

        def compile_person(entry, node, context)
          unless entry.is_a?(Hash)
            context.error!("people entries must be mappings", line: node.start_line)
          end

          unexpected = (entry.keys - ALLOWED_KEYS).first
          if unexpected
            context.error!(
              %(people entry does not accept key "#{unexpected}"),
              line: node.start_line
            )
          end
          REQUIRED_KEYS.each do |key|
            unless entry.key?(key)
              context.error!(%(people entry requires "#{key}"), line: node.start_line)
            end
            validate_nonblank_string!(entry[key], key, node, context)
          end
          if entry.key?("url")
            validate_nonblank_string!(entry["url"], "url", node, context)
            validate_url!(entry["url"], node, context)
          end

          person = {
            "name" => entry.fetch("name"),
            "role" => entry.fetch("role"),
            "image" => {
              "src" => entry.fetch("image"),
              "alt" => "Portrait of #{entry.fetch("name")}"
            }
          }
          person["url"] = entry.fetch("url") if entry.key?("url")
          person
        end

        def validate_nonblank_string!(value, key, node, context)
          return if value.is_a?(String) && !value.strip.empty?

          context.error!(
            %(people entry "#{key}" must be a nonblank string),
            line: node.start_line
          )
        end

        def validate_url!(url, node, context)
          root = Kramdown::Element.new(:root)
          root.children << Kramdown::Element.new(:a, nil, { "href" => url })
          MarkdownValidator.validate_safety!(
            root,
            component: self.class.type,
            context: context,
            line: node.start_line
          )
        end
      end
    end
  end
end
