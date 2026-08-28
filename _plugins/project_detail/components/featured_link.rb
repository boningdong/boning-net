# frozen_string_literal: true

require "kramdown"
require_relative "base"

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
          return if each_element(link).any? { |element| %i[img html_element].include?(element.type) }
          return if link.attr.fetch("href", "").strip.empty?

          link
        end

        def visible_children(element)
          element.children.reject do |child|
            child.type == :blank || child.type == :xml_comment ||
              (child.type == :text && child.value.strip.empty?)
          end
        end

        def each_element(root)
          [root, *root.children.flat_map { |child| each_element(child) }]
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
      end
    end
  end
end
