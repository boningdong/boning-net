# frozen_string_literal: true

require_relative "errors"

module BoningNet
  module ProjectDetail
    class RenderContext
      attr_reader :current_heading_label
      attr_reader :source_path, :frontmatter, :kramdown_options, :blocks

      def initialize(source_path:, frontmatter:, kramdown_options:, source_line_offset: 0)
        @source_path = source_path
        @source_line_offset = source_line_offset
        @frontmatter = frontmatter || {}
        @kramdown_options = kramdown_options || {}
        @current_heading_label = nil
        @current_heading_identity = nil
        @figure_counters = Hash.new(0)
        @blocks = {}
      end

      def store_block(block)
        id = "project-detail-block-#{@blocks.length + 1}"
        @blocks[id] = block
        id
      end

      def next_figure_number
        @figure_counters[@current_heading_identity] += 1
      end

      def use_heading(label:, location:)
        @current_heading_label = label
        @current_heading_identity = location
      end

      def error!(message, line:)
        raise ConfigurationError, "#{@source_path}:#{line + @source_line_offset}: #{message}"
      end
    end
  end
end
