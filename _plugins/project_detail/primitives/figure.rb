# frozen_string_literal: true

require_relative "caption"

module BoningNet
  module ProjectDetail
    module Primitives
      class Figure
        def initialize(src:, alt:, title:, context:, line:)
          @src = src
          @alt = alt
          @title = title
          @context = context
          @line = line
        end

        def to_h
          validate!
          number = @context.next_figure_number
          block = {
            "type" => "figure",
            "image" => { "src" => @src, "alt" => @alt }
          }
          block["caption"] = caption(number) if caption?
          block
        end

        private

        def validate!
          if @alt.to_s.strip.empty?
            @context.error!("figure alt text is required", line: @line)
          end

          if @src.to_s.strip.empty?
            @context.error!("figure image source is required", line: @line)
          end
        end

        def caption?
          !@title.nil? && !@title.empty?
        end

        def caption(number)
          Caption.new(
            text: @title,
            heading_label: @context.current_heading_label,
            number: number
          ).to_h
        end
      end
    end
  end
end
