# frozen_string_literal: true

require_relative "../primitives/figure"

module BoningNet
  module ProjectDetail
    module Components
      class StandaloneFigure
        def self.match?(element)
          return false unless element.type == :p

          visible_children = element.children.reject do |child|
            child.type == :text && child.value.strip.empty?
          end
          visible_children.length == 1 && visible_children.first.type == :img
        end

        def initialize(paragraph:, context:)
          @paragraph = paragraph
          @context = context
        end

        def compile
          image = @paragraph.children.find { |child| child.type == :img }
          Primitives::Figure.new(
            src: image.attr["src"],
            alt: image.attr["alt"],
            title: image.attr["title"],
            context: @context,
            line: @paragraph.options.fetch(:location)
          ).to_h
        end
      end
    end
  end
end
