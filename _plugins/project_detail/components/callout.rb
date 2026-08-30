# frozen_string_literal: true

require "kramdown"
require_relative "base"
require_relative "markdown_validator"

module BoningNet
  module ProjectDetail
    module Components
      class Callout < Base
        register_as "callout"

        def compile(node, context)
          reject_attributes!(node, context)
          document = Kramdown::Document.new(node.body, context.kramdown_options)
          visible = visible_children(document.root)
          lead = visible.first
          unless emphasized_lead?(lead)
            context.error!(
              "callout must begin with one paragraph containing only a strong or emphasis lead",
              line: node.start_line
            )
          end

          allowed_content = visible.all? do |element|
            MarkdownValidator.allowed_tree?(element, types: MarkdownValidator::CALLOUT_TYPES)
          end
          unless allowed_content
            context.error!(
              "callout may contain only paragraphs, lists, and links",
              line: node.start_line
            )
          end
          MarkdownValidator.validate_safety!(
            document.root,
            component: self.class.type,
            context: context,
            line: node.start_line
          )

          { "type" => self.class.type, "html" => document.to_html }
        end

        private

        def reject_attributes!(node, context)
          attribute = node.attributes.keys.first
          return unless attribute

          context.error!(
            %(callout does not accept attribute "#{attribute}"),
            line: node.start_line
          )
        end

        def visible_children(element)
          element.children.reject do |child|
            child.type == :blank || child.type == :xml_comment ||
              (child.type == :text && child.value.strip.empty?)
          end
        end

        def emphasized_lead?(paragraph)
          return false unless paragraph&.type == :p

          children = visible_children(paragraph)
          children.length == 1 && %i[strong em].include?(children.first.type)
        end
      end
    end
  end
end
