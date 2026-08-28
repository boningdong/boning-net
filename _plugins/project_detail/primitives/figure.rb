# frozen_string_literal: true

require "uri"
require_relative "caption"
require_relative "../entity_decoder"

module BoningNet
  module ProjectDetail
    module Primitives
      class Figure
        def initialize(src:, alt:, title:, context:, line:)
          @src = EntityDecoder.decode_once(src)
          @alt = EntityDecoder.decode_once(alt)
          @title = EntityDecoder.decode_once(title)
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

          unless safe_image_source?(@src)
            @context.error!(
              "figure image source must be relative or use http or https",
              line: @line
            )
          end
        end

        def safe_image_source?(value)
          return false if value.match?(/[\u0000-\u001f\u007f]/)
          return false if value[0, 2]&.each_char&.all? { |character| ["/", "\\"].include?(character) }

          uri = URI.parse(value)
          !uri.scheme || %w[http https].include?(uri.scheme.downcase)
        rescue URI::InvalidURIError
          false
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
