# frozen_string_literal: true

require "kramdown"
require_relative "base"
require_relative "../primitives/collection"
require_relative "../primitives/figure"

module BoningNet
  module ProjectDetail
    module Components
      class Gallery < Base
        LAYOUTS = {
          2 => "two",
          3 => "three",
          4 => "four"
        }.freeze
        IMAGE_ATTRIBUTES = %w[src alt title].freeze

        register_as "gallery"

        def compile(node, context)
          reject_attributes!(node, context)
          document = Kramdown::Document.new(node.body, context.kramdown_options)
          children = document.root.children.reject { |child| child.type == :blank }
          if children.empty?
            context.error!(
              "gallery must contain standalone Markdown images",
              line: node.start_line
            )
          end
          unless children.all? { |child| standalone_image_paragraph?(child) }
            context.error!(
              "gallery may contain only standalone Markdown images separated by blank lines",
              line: node.start_line
            )
          end
          if children.length == 1
            context.error!(
              "gallery requires at least two images; use a plain Markdown image instead",
              line: node.start_line
            )
          end

          items = children.map do |paragraph|
            compile_image(paragraph, node, context)
          end
          collection = Primitives::Collection.new(
            items: items,
            layouts: LAYOUTS,
            overflow_layout: "masonry"
          ).to_h

          { "type" => self.class.type }.merge(collection)
        end

        private

        def reject_attributes!(node, context)
          attribute = node.attributes.keys.first
          return unless attribute

          context.error!(
            %(gallery does not accept attribute "#{attribute}"),
            line: node.start_line
          )
        end

        def standalone_image_paragraph?(paragraph)
          paragraph.type == :p && paragraph.children.length == 1 &&
            paragraph.children.first.type == :img
        end

        def compile_image(paragraph, node, context)
          image = paragraph.children.find { |child| child.type == :img }
          validate_image_attributes!(image, paragraph, node, context)
          Primitives::Figure.new(
            src: image.attr["src"],
            alt: image.attr["alt"],
            title: image.attr["title"],
            context: context,
            line: source_line(paragraph, node)
          ).to_h
        end

        def validate_image_attributes!(image, paragraph, node, context)
          unexpected = image.attr.keys - IMAGE_ATTRIBUTES
          ial = image.options[:ial]
          return if unexpected.empty? && (ial.nil? || ial.empty?)

          context.error!(
            "gallery images do not allow inline attribute lists",
            line: source_line(paragraph, node)
          )
        end

        def source_line(paragraph, node)
          node.start_line + paragraph.options.fetch(:location)
        end
      end
    end
  end
end
