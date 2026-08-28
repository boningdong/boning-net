# frozen_string_literal: true

require "kramdown"
require_relative "base"
require_relative "markdown_validator"

module BoningNet
  module ProjectDetail
    module Components
      class FeaturedLink < Base
        register_as "featured-link"

        def compile(node, context)
          reject_attributes!(node, context)
          document = Kramdown::Document.new(node.body, context.kramdown_options)
          link = standalone_link(document)
          unless link
            context.error!(
              "featured-link must contain exactly one standalone Markdown link",
              line: node.start_line
            )
          end
          MarkdownValidator.validate_safety!(
            document.root,
            component: self.class.type,
            context: context,
            line: node.start_line
          )
          if plain_text(link).match?(/\A\p{Space}*\z/)
            context.error!(
              "featured-link link text is required for accessibility",
              line: node.start_line
            )
          end

          {
            "type" => self.class.type,
            "url" => link.attr.fetch("href"),
            "label_html" => render_label(link, document)
          }
        end

        private

        def reject_attributes!(node, context)
          attribute = node.attributes.keys.first
          return unless attribute

          context.error!(
            %(featured-link does not accept attribute "#{attribute}"),
            line: node.start_line
          )
        end

        def standalone_link(document)
          visible = visible_children(document.root)
          return unless visible.length == 1 && visible.first.type == :p

          children = visible_children(visible.first)
          return unless children.length == 1 && children.first.type == :a

          link = children.first
          return unless MarkdownValidator.allowed_tree?(
            visible.first,
            types: MarkdownValidator::INLINE_TYPES
          )
          return if link.attr.fetch("href", "").strip.empty?

          link
        end

        def visible_children(element)
          element.children.reject do |child|
            child.type == :blank ||
              (child.type == :text && child.value.strip.empty?)
          end
        end

        def render_label(link, document)
          root = Kramdown::Element.new(
            :root,
            nil,
            nil,
            { encoding: document.root.options.fetch(:encoding) }
          )
          root.children = link.children
          Kramdown::Converter::Html.convert(root, document.options).first
        end

        def plain_text(element)
          case element.type
          when :text, :codespan
            element.value.to_s
          when :entity
            element.value.code_point.chr(Encoding::UTF_8)
          when :br
            " "
          when :smart_quote, :typographic_sym
            Kramdown::Utils::Entities.entity(element.value.to_s).code_point.chr(Encoding::UTF_8)
          else
            element.children.map { |child| plain_text(child) }.join
          end
        end
      end
    end
  end
end
