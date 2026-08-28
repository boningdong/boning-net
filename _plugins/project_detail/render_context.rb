# frozen_string_literal: true

require_relative "errors"

module BoningNet
  module ProjectDetail
    class RenderContext
      attr_accessor :current_heading_label
      attr_reader :source_path, :frontmatter, :kramdown_options, :blocks

      def initialize(source_path:, frontmatter:, kramdown_options:)
        @source_path = source_path
        @frontmatter = frontmatter || {}
        @kramdown_options = kramdown_options || {}
        @current_heading_label = nil
        @figure_counters = Hash.new(0)
        @blocks = {}
      end

      def store_block(block)
        id = "project-detail-block-#{@blocks.length + 1}"
        @blocks[id] = block
        id
      end

      def next_figure_number
        @figure_counters[@current_heading_label] += 1
      end

      def error!(message, line:)
        raise ConfigurationError, "#{@source_path}:#{line}: #{message}"
      end
    end
  end
end
