# frozen_string_literal: true

require "shellwords"
require_relative "errors"

module BoningNet
  module ProjectDetail
    DirectiveNode = Struct.new(
      :name,
      :attributes,
      :body,
      :start_line,
      :end_line,
      keyword_init: true
    )

    class DirectiveParser
      DIRECTIVE_NAME = /\A[A-Za-z][A-Za-z0-9-]*\z/
      ATTRIBUTE_NAME = /\A[A-Za-z][A-Za-z0-9_-]*\z/
      FENCE_OPENING = /\A[ \t]*(`{3,}|~{3,})[^\n]*\z/
      DIRECTIVE_OPENING = /\A[ \t]*:::[ \t]+(.+?)[ \t]*\z/
      DIRECTIVE_CLOSING = /\A[ \t]*:::[ \t]*\z/

      def initialize(markdown:, source_path:)
        @markdown = markdown
        @source_path = source_path
      end

      def call
        nodes = []
        directive = nil
        body_lines = []
        fence = nil

        @markdown.lines.each_with_index do |line, index|
          line_number = index + 1
          text = line.chomp

          if fence
            fence = nil if closing_fence?(text, fence)
            body_lines << line if directive
            next
          end

          if (opening_fence = FENCE_OPENING.match(text))
            fence = opening_fence[1]
            body_lines << line if directive
            next
          end

          if directive
            if DIRECTIVE_CLOSING.match?(text)
              nodes << directive_node(directive, body_lines.join, line_number)
              directive = nil
              body_lines = []
            elsif DIRECTIVE_OPENING.match?(text)
              error!("nested directive is not allowed", line_number)
            else
              body_lines << line
            end
          elsif DIRECTIVE_CLOSING.match?(text)
            error!("stray closing marker", line_number)
          elsif (opening = DIRECTIVE_OPENING.match(text))
            directive = parse_opening(opening[1], line_number)
          end
        end

        if directive
          error!(%(missing closing marker for directive "#{directive.fetch(:name)}"), directive.fetch(:start_line))
        end

        nodes.freeze
      end

      private

      def parse_opening(header, line)
        tokens = Shellwords.split(header)
        name = tokens.shift
        error!("malformed directive name", line) unless name&.match?(DIRECTIVE_NAME)

        attributes = tokens.each_with_object({}) do |token, parsed|
          key, value = token.split("=", 2)
          unless value && key.match?(ATTRIBUTE_NAME)
            error!(%(malformed directive attribute "#{token}"), line)
          end

          parsed[key] = value
        end

        { name: name, attributes: attributes, start_line: line }
      rescue ArgumentError
        error!("malformed directive attributes", line)
      end

      def directive_node(directive, body, end_line)
        name = directive.fetch(:name).dup.freeze
        attributes = directive.fetch(:attributes).each_with_object({}) do |(key, value), frozen_attributes|
          frozen_attributes[key.dup.freeze] = value.dup.freeze
        end.freeze

        DirectiveNode.new(
          name: name,
          attributes: attributes,
          body: body.dup.freeze,
          start_line: directive.fetch(:start_line),
          end_line: end_line
        ).freeze
      end

      def closing_fence?(text, fence)
        marker = Regexp.escape(fence[0])
        text.match?(Regexp.new("\\A[ \\t]*#{marker}{#{fence.length},}[ \\t]*\\z"))
      end

      def error!(message, line)
        raise ConfigurationError, "#{@source_path}:#{line}: #{message}"
      end
    end
  end
end
