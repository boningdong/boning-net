# frozen_string_literal: true

require "kramdown"
require_relative "base"

module BoningNet
  module ProjectDetail
    module Components
      class Callout < Base
        register_as "callout"

        ALLOWED_TYPES = %i[
          root p ul ol li text strong em a codespan entity typographic_sym smart_quote br
        ].freeze

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

          unless visible.all? { |element| allowed_tree?(element) }
            context.error!(
              "callout may contain only paragraphs, lists, and links",
              line: node.start_line
            )
          end

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

        def allowed_tree?(element)
          ALLOWED_TYPES.include?(element.type) && element.children.all? { |child| allowed_tree?(child) }
        end
      end
    end
  end
end
