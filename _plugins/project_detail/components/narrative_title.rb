# frozen_string_literal: true

require "kramdown"
require_relative "base"

module BoningNet
  module ProjectDetail
    module Components
      class NarrativeTitle < Base
        register_as "narrative-title"

        def compile(node, context)
          reject_attributes!(node, context)
          unless context.current_heading_level == 1 && context.first_visible_after_heading
            context.error!(
              "narrative-title must be the first visible block after an H1",
              line: node.start_line
            )
          end

          document = Kramdown::Document.new(node.body, context.kramdown_options)
          visible = visible_children(document.root)
          unless visible.length == 1 && visible.first.type == :p && inline_paragraph?(visible.first)
            context.error!(
              "narrative-title must contain exactly one inline Markdown paragraph",
              line: node.start_line
            )
          end

          {
            "type" => self.class.type,
            "html" => document.to_html,
            "marks_chapter" => true
          }
        end

        private

        def reject_attributes!(node, context)
          attribute = node.attributes.keys.first
          return unless attribute

          context.error!(
            %(narrative-title does not accept attribute "#{attribute}"),
            line: node.start_line
          )
        end

        def visible_children(element)
          element.children.reject do |child|
            child.type == :blank || child.type == :xml_comment ||
              (child.type == :text && child.value.strip.empty?)
          end
        end

        def inline_paragraph?(paragraph)
          each_element(paragraph).none? do |element|
            %i[img html_element].include?(element.type)
          end
        end

        def each_element(root)
          [root, *root.children.flat_map { |child| each_element(child) }]
        end
      end
    end
  end
end
